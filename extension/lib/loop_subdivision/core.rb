module LoopSubdivision
  module Core
    Point = Struct.new(:x, :y, :z) do
      def +(other); Point.new(x + other.x, y + other.y, z + other.z); end
      def *(scalar); Point.new(x * scalar, y * scalar, z * scalar); end
      def /(scalar); Point.new(x / scalar, y / scalar, z / scalar); end
      def to_a; [x, y, z]; end
    end

    Triangle = Struct.new(:v, :material, :back_material)
    Mesh = Struct.new(:vertices, :faces, :edges, :boundary_edges, :neighbors, :edge_opposites, :crease_edges)

    module_function

    def point_from_sketchup(p)
      Point.new(p.x.to_f, p.y.to_f, p.z.to_f)
    end

    def key_for_point(p)
      [p.x.round(6), p.y.round(6), p.z.round(6)]
    end

    def extract(entities)
      vertices = []
      vertex_map = {}
      triangles = []
      crease_keys = []
      visit = lambda do |collection|
        collection.each do |entity|
          case entity
          when Sketchup::Group
            visit.call(entity.entities) unless entity.get_attribute('LoopSubdivision', 'role') == 'surface'
          when Sketchup::ComponentInstance
            visit.call(entity.definition.entities)
          when Sketchup::Edge
            if entity.get_attribute('LoopSubdivision', 'crease', false) == true
              a = key_for_point(point_from_sketchup(entity.start.position))
              b = key_for_point(point_from_sketchup(entity.end.position))
              crease_keys << ((a <=> b) <= 0 ? [a, b] : [b, a])
            end
          when Sketchup::Face
            mesh = entity.mesh(0)
            mesh.count_polygons.times do |i|
              poly = mesh.polygon_points_at(i + 1)
              next unless poly && poly.length == 3
              ids = poly.map do |p|
                local = point_from_sketchup(p)
                key = key_for_point(local)
                vertex_map[key] ||= begin
                  vertices << local
                  vertices.length - 1
                end
              end
              next if ids.uniq.length < 3
              triangles << Triangle.new(ids, entity.material, entity.back_material)
            end
          end
        end
      end
      visit.call(entities)
      build_topology(vertices, triangles, crease_keys)
    end

    def build_topology(vertices, faces, crease_keys = [])
      edges = {}
      neighbors = Array.new(vertices.length) { [] }
      edge_opposites = Hash.new { |h, k| h[k] = [] }
      faces.each do |face|
        a, b, c = face.v
        [[a, b, c], [b, c, a], [c, a, b]].each do |u, v, opposite|
          key = u < v ? [u, v] : [v, u]
          edges[key] = true
          neighbors[u] << v unless neighbors[u].include?(v)
          neighbors[v] << u unless neighbors[v].include?(u)
          edge_opposites[key] << opposite unless edge_opposites[key].include?(opposite)
        end
      end
      boundary_edges = edges.keys.select { |e| edge_opposites[e].length == 1 }
      index_by_key = {}
      vertices.each_with_index { |p, i| index_by_key[key_for_point(p)] = i }
      crease_edges = crease_keys.map do |pair|
        a = index_by_key[pair[0]]
        b = index_by_key[pair[1]]
        next nil if a.nil? || b.nil?
        a < b ? [a, b] : [b, a]
      end.compact.uniq.select { |e| edges.key?(e) }
      Mesh.new(vertices, faces, edges.keys, boundary_edges, neighbors, edge_opposites, crease_edges)
    end

    def subdivide(mesh)
      old_v = mesh.vertices
      edge_points = {}
      new_vertices = old_v.map { |p| p }

      mesh.edges.each do |edge|
        a, b = edge
        opposites = mesh.edge_opposites[edge]
        if mesh.crease_edges.include?(edge)
          p = (old_v[a] + old_v[b]) / 2.0
        elsif opposites.length >= 2
          p = old_v[a] * (3.0 / 8.0) + old_v[b] * (3.0 / 8.0) +
              old_v[opposites[0]] * (1.0 / 8.0) + old_v[opposites[1]] * (1.0 / 8.0)
        else
          p = (old_v[a] + old_v[b]) / 2.0
        end
        edge_points[edge] = new_vertices.length
        new_vertices << p
      end

      vertex_points = []
      old_v.each_index do |i|
        crease_neighbors = []
        mesh.crease_edges.each do |edge|
          if edge.include?(i)
            crease_neighbors << (edge[0] == i ? edge[1] : edge[0])
          end
        end
        crease_neighbors.uniq!
        if crease_neighbors.length >= 3
          p = old_v[i]
          vertex_points << p
          next
        elsif crease_neighbors.length == 2
          p = old_v[i] * 0.75 +
              (old_v[crease_neighbors[0]] + old_v[crease_neighbors[1]]) * 0.125
          vertex_points << p
          next
        end

        boundary_neighbors = []
        mesh.boundary_edges.each do |edge|
          if edge.include?(i)
            boundary_neighbors << (edge[0] == i ? edge[1] : edge[0])
          end
        end
        boundary_neighbors.uniq!
        if boundary_neighbors.length >= 2
          p = old_v[i] * 0.75 +
              (old_v[boundary_neighbors[0]] + old_v[boundary_neighbors[1]]) * 0.125
        else
          n = mesh.neighbors[i].length
          if n < 3
            p = old_v[i]
          else
            beta = (n == 3) ? (3.0 / 16.0) : (3.0 / (8.0 * n))
            sum = mesh.neighbors[i].reduce(Point.new(0.0, 0.0, 0.0)) { |acc, j| acc + old_v[j] }
            p = old_v[i] * (1.0 - n * beta) + sum * beta
          end
        end
        vertex_points << p
      end
      vertex_points.each_with_index { |p, i| new_vertices[i] = p }

      new_faces = []
      mesh.faces.each do |face|
        a, b, c = face.v
        ab = edge_points[a < b ? [a, b] : [b, a]]
        bc = edge_points[b < c ? [b, c] : [c, b]]
        ca = edge_points[c < a ? [c, a] : [a, c]]
        new_faces << Triangle.new([a, ab, ca], face.material, face.back_material)
        new_faces << Triangle.new([ab, b, bc], face.material, face.back_material)
        new_faces << Triangle.new([ca, bc, c], face.material, face.back_material)
        new_faces << Triangle.new([ab, bc, ca], face.material, face.back_material)
      end
      new_crease_edges = []
      mesh.crease_edges.each do |edge|
        a, b = edge
        e = edge_points[edge]
        new_crease_edges << (a < e ? [a, e] : [e, a])
        new_crease_edges << (b < e ? [b, e] : [e, b])
      end
      build_topology(new_vertices, new_faces, []) .tap do |result|
        result.crease_edges.replace(new_crease_edges.uniq.select { |e| result.edges.include?(e) })
      end
    end

    def subdivide_repeated(mesh, levels)
      levels.to_i.times { mesh = subdivide(mesh) }
      mesh
    end
  end
end
