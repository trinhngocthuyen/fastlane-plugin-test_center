module TestCenter
  module Helper
    require 'fastlane/actions/scan'
    require 'fastlane/snapshot'
    class SimulatorHelper
    
      def initialize(devices, duplicates_to_make)
        @batch_simulators = []
        if devices.count > 0
          simulators = Scan.detect_simulator(devices, '', '', '', nil)
          (1..duplicates_to_make).each do |index|
            @batch_simulators << []
            simulators.each do |requested_simulator|
              @batch_simulators[index] << "#{requested_simulator.name}-multiscan-#{index} (#{requested_simulator.os_version})"
              Snapshot::ResetSimulators.create(requested_simulator.os_type, requested_simulator.os_version, "#{requested_simulator.name}-multiscan-#{index}")
            end
          end
        end
      end

      def scan_options_for_batch(batch)
        @batch_simulators[batch].join(',')
      end

      def delete_duplicated_simulators
        @batch_simulators.each do |simulators|
          simulators.each do |simulator|
            device = FastlaneCore::DeviceManager::Device.new(simulator)
            device.delete
          end
        end
      end
    end
  end
end