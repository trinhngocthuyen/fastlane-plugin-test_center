module TestCenter
  module Helper
    module RetryingScan
      module SimulatorManager
        require 'scan'

      # This class will take the standard scan destinatons, and create clones
      # it will provide the scan destinations for each parallelized sim run
      # it will delete the clones if 
        def setup_simulators
          return if @batch_count == 1

          @simulators ||= []

          found_simulator_devices = []

          devices = @scan_options[:devices] || Array(@scan_options[:device])
          if devices.count > 0
            found_simulator_devices = Scan::DetectValues.detect_simulator(devices, '', '', '', nil)
          else
            found_simulator_devices = Scan::DetectValues.detect_simulator(devices, 'iOS', 'IPHONEOS_DEPLOYMENT_TARGET', 'iPhone 5s', nil)
          end
          (0...@batch_count).each do |batch_index|
            @simulators[batch_index] ||= []

            found_simulator_devices.each do |found_simulator_device|
              device_for_batch = found_simulator_device.clone
              device_for_batch.rename("#{found_simulator_device.name}-batchclone-#{batch_index}")
              @simulators[batch_index] << device_for_batch
            end
          end
        end

        def cleanup_simulators
          @simulators.flatten.each(&:delete)
          @simulators = []
        end

        def devices(batch_index)
          if @simulators.count > 0
            @simulators[batch_index].map do |simulator|
              "#{simulator.name} (#{simulator.os_version})"
            end
          else
            @scan_options[:devices] || Array(@scan_options[:device])
          end
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
        self.name = newname
      end
    end
  end
end
