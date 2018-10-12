describe TestCenter::Helper::RetryingScan do
  SimulatorManager = TestCenter::Helper::RetryingScan::SimulatorManager
  describe 'simulator_manager', simulator_manager: true do
    describe 'batch_count is 1' do
      class SingleBatch
        include SimulatorManager

        def initialize
          @batch_count = 1
          @scan_options = {
            devices: ['iPhone 5s (98.0)']
          }
          super()
        end
      end

      describe '#setup_simulators' do
        it 'does not clone any simulator devices' do
          single = SingleBatch.new
          expect(SingleBatch).not_to receive(:`)
          single.setup_simulators
        end
      end

      describe '#devices' do
        it 'returns the default devices for \'batch 1\'' do
          single = SingleBatch.new
          expect(single.devices(1)).to eq(['iPhone 5s (98.0)'])
        end

        it 'raises an exception for \'batch 99\'' do
          single = SingleBatch.new
          expect { single.devices(99) }.to(
            raise_error(Exception) do |error|
              expect(error.message).to match("Error: impossible to request devices for batch 99, there are only 1 set(s) of simulators")
            end
          )
        end
      end
    end

  end
end
