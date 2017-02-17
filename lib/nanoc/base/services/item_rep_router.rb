module Nanoc::Int
  # Assigns paths to reps.
  #
  # @api private
  class ItemRepRouter
    class IdenticalRoutesError < ::Nanoc::Error
      def initialize(output_path, rep_a, rep_b)
        super("The item representations #{rep_a.inspect} and #{rep_b.inspect} are both routed to #{output_path}.")
      end
    end

    class RouteWithoutSlashError < ::Nanoc::Error
      def initialize(output_path, rep)
        super("The item representation #{rep.inspect} is routed to #{output_path}, which does not start with a slash, as required.")
      end
    end

    def initialize(reps, action_provider, site)
      @reps = reps
      @action_provider = action_provider
      @site = site
    end

    def run
      assigned_paths = {}
      @reps.each do |rep|
        @action_provider.paths_for(rep).each do |(snapshot_names, paths)|
          route_rep(rep, paths, snapshot_names, assigned_paths)
        end
      end
    end

    def route_rep(rep, paths, snapshot_names, assigned_paths)
      # Encode
      paths = paths.map { |path| path.encode('UTF-8') }

      # Validate format
      paths.each do |path|
        unless path.start_with?('/')
          raise RouteWithoutSlashError.new(path, rep)
        end
      end

      # Validate uniqueness
      paths.each do |path|
        if assigned_paths.include?(path)
          # TODO: Include snapshot names in error message
          raise IdenticalRoutesError.new(path, assigned_paths[path], rep)
        end
      end
      paths.each do |path|
        assigned_paths[path] = rep
      end

      # TODO: allow multiple
      path = paths.first
      snapshot_name = snapshot_names.first
      return if path.nil?
      basic_path = path

      rep.raw_paths[snapshot_name] = @site.config[:output_dir] + basic_path
      rep.paths[snapshot_name] = strip_index_filename(basic_path)
    end

    def strip_index_filename(basic_path)
      @site.config[:index_filenames].each do |index_filename|
        slashed_index_filename = '/' + index_filename
        if basic_path.end_with?(slashed_index_filename)
          return basic_path[0..-index_filename.length - 1]
        end
      end

      basic_path
    end
  end
end
