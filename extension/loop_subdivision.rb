require 'sketchup.rb'
require 'digest'
# LoopsubD 2 v2.7.3 - Loop subdivision for SketchUp
require_relative 'lib/loop_subdivision/core'
require_relative 'lib/loop_subdivision/controller'
require_relative 'lib/loop_subdivision/crease'
require_relative 'lib/loop_subdivision/observer'

module LoopSubdivision
  unless file_loaded?(__FILE__)
    LoopSubdivision::Controller.install_menu
    LoopSubdivision::Controller.install_toolbar
    LoopSubdivision::Observer.install
    file_loaded(__FILE__)
  end
end
