require 'tempfile'
require 'fileutils'

module FPM
  class Job
    def self.build(name, &block)
      new(name).build(&block)
    end

    def initialize(name)
      @name = name
    end

    attr_reader :name
    attr_accessor :chdir, :verbose, :after_install, :source, :target, :version, :prefix, :package

    def build
      yield self

      run
    end

    def dependencies
      @dependencies ||= []
    end

    def source_files
      @source_files ||= []
    end

    def run
      Tempfile.open('fpm') do |file|
        path = file.path
        file.close

        output = [ 'fpm' ]
        output << '--verbose' if @verbose
        output << "--after-install #{File.expand_path(@after_install)}" if @after_install
        dependencies.flatten.each { |dependency| output << "-d #{dependency}" }
        output << "-s #{@source}"
        output << "-t #{@target}"
        output << %{-n "#{@name}"}
        output << %{-v "#{@version}"}
        output << "--prefix #{@prefix}" if @prefix
        output << "-p #{file.path}"
        source_files.each { |file| output << file }

        Dir.chdir(@chdir) do
          file.unlink
          system output.join(' ')
        end

        File.unlink(@package) if File.file?(@package)
        FileUtils.mkdir_p File.dirname(@package)
        FileUtils.mv path, @package
      end
    end
  end
end

