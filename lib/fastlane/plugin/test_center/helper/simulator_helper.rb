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
              
              udid = `xcrun simctl clone #{requested_simulator.udid} "#{requested_simulator.name}-multiscan-#{index + 1}"`.chomp
              @batch_simulators[index] << {
                name: "#{requested_simulator.name}-multiscan-#{index + 1}",
                udid: udid
              }
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
            `xcrun simctl delete #{simulator[:udid]}`
          end
        end
      end
    end
  end
end