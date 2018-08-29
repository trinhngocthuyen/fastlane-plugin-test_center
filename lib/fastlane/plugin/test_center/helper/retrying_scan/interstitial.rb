module TestCenter
  module Helper
    module RetryingScan
      class Interstitial
        def initialize(options)
          @create_test_result_bundle = options[:test_result]
          @output_directory = options[:output_directory]
          before_all
        end

        def before_all
          if @create_test_result_bundle
            remove_preexisting_test_result_bundles
          end
        end

        def remove_preexisting_test_result_bundles
          glob_pattern = "#{@output_directory}/.*\.test_result"
          preexisting_test_result_bundles = Dir.glob(glob_pattern)
          FileUtils.rm_rf(preexisting_test_result_bundles)
        end
      end
    end
  end
end
