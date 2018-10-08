module TestCenter
  module Helper
    module RetryingScan
      module ParallelizedSimulators
        require 'scan'

        @simulators = []
      # This class will take the standard scan destinatons, and create clones
      # it will provide the scan destinations for each parallelized sim run
      # it will delete the clones if 
        def prepare_for_parallelized_scan(options, clone_count)
          devices = options[:devices] || Array(options[:device])
          if devices.count > 0
            simulators = Scan::DetectValues.detect_simulator(devices, '', '', '', nil)
          else
            simulators = Scan::DetectValues.detect_simulator(devices, 'iOS', 'IPHONEOS_DEPLOYMENT_TARGET', 'iPhone 5s', nil)
          end
          byebug
        end

        def batchscan_options(batch)

        end
      end
    end
  end
end

module FastlaneCore
  class DeviceManager
    class Device
      def clone
        raise 'Can only clone iOS Simulators' unless self.is_simulator

        Device.new(
          name: self.name,
          udid: `xcrun simctl clone #{self.udid} '#{self.name}'`.chomp,
          os_type: self.os_type,
          os_version: self.os_version,
          state: self.state,
          is_simulator: self.is_simulator
        )
      end

      def rename(newname)
        `xcrun simctl rename #{self.udid} '#{newname}''`
      end
    end
  end
end
