describe TestCenter::Helper::RetryingScan do
  SimulatorManager = TestCenter::Helper::RetryingScan::SimulatorManager
  describe 'simulator_manager', simulator_manager: true do
    describe 'batch_count is 1' do
      before(:each) do
        device = OpenStruct.new(
          name: 'iPhone 5s',
          udid: 'B56B326E-0060-46F0-90EB-EFD433A03232',
          os_type: 'iOS',
          os_version: '12.0',
          ios_version: '12.0',
          state: 'Shutdown',
          is_simulator: true
        )
        allow(Scan::DetectValues).to receive(:detect_simulator).and_return([device])
      end

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
        before(:each) do
          @single = SingleBatch.new
          @single.setup_simulators
        end

        it 'returns no cloned devices for batch 1' do
          expect(@single.devices(1)).to eq(['iPhone 5s (98.0)'])
        end
        it 'raises an exception for \'batch 99\'' do
          expect { @single.devices(99) }.to(
            raise_error(Exception) do |error|
              expect(error.message).to match("Error: impossible to request devices for batch 99, there are only 1 set(s) of simulators")
            end
          )
        end
      end
    end

    describe 'batch_count is 2' do
      before(:each) do
        device = OpenStruct.new(
          name: 'iPhone 5s',
          udid: 'B56B326E-0060-46F0-90EB-EFD433A03232',
          os_type: 'iOS',
          os_version: '12.0',
          ios_version: '12.0',
          state: 'Shutdown',
          is_simulator: true
        )
        clones = [device.clone, device.clone]
        clone_index = 0
        allow(device).to receive(:clone) do
          clone_index += 1
          clones[clone_index - 1]
        end
        allow(clones[0]).to receive(:rename) do |new_name|
          clones[0].name = new_name
        end
        allow(clones[1]).to receive(:rename) do |new_name|
          clones[1].name = new_name
        end
        allow(Scan::DetectValues).to receive(:detect_simulator).and_return([device])
      end

      class MultiBatch
        include SimulatorManager

        def initialize
          @batch_count = 2
          @scan_options = {
            devices: ['iPhone 5s (98.0)']
          }
          super()
        end
      end

      describe '#setup_simulators' do
        it 'does clone simulator devices' do
          multi = MultiBatch.new
          multi.setup_simulators
        end
      end

      describe '#devices' do
        before(:each) do
          @multi = MultiBatch.new
          @multi.setup_simulators
        end

        it 'returns cloned devices for batch 1' do
          expect(@multi.devices(1)).to eq(["iPhone 5s-batchclone-1 (12.0)"])
        end

        it 'returns cloned devices for batch 2' do
          expect(@multi.devices(2)).to eq(["iPhone 5s-batchclone-2 (12.0)"])
        end

        it 'raises an exception for \'batch 99\'' do
          expect { @multi.devices(99) }.to(
            raise_error(Exception) do |error|
              expect(error.message).to match("Error: impossible to request devices for batch 99, there are only 2 set(s) of simulators")
            end
          )
        end
      end
    end
  end
end
