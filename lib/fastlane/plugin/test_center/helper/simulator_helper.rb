module FastlaneCore
  class DeviceManager
    class Device
      def clone
        raise 'Can only clone iOS Simulators' unless self.is_simulator

        Device.new(
          name: "#{self.name}-multi_scan",
          udid: `xcrun simctl clone #{self.udid} '#{self.name}-multi_scan'`.chomp,
          os_type: self.os_type,
          os_version: self.os_version,
          state: self.state,
          is_simulator: self.is_simulator
        )
      end
    end
  end
end

module TestCenter
  module Helper
    require 'scan'
    class SimulatorHelper
    
      def initialize(devices, duplicates_to_make)
        @batch_simulators = []
        
        if devices.count > 0
          simulators = Scan::DetectValues.detect_simulator(devices, '', '', '', nil)
          
          (0...duplicates_to_make).each do |index|
            @batch_simulators << []
            simulators.each do |requested_simulator|
              @batch_simulators[index] << requested_simulator.clone
            end
          end
        end
      end

      def scan_options_for_batch(batch)
        @batch_simulators[batch].map { |record| record[:name] }.join(',')
      end

      def delete_duplicated_simulators
        @batch_simulators.each do |simulators|
          byebug
          simulators.each do |simulator|
            simulator.delete
          end
        end
      end
    end
  end
end