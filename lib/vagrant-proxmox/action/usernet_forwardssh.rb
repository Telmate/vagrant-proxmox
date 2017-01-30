module VagrantPlugins
	module Proxmox
		module Action

			# This action create a usernetwork with SSH for unpredictable networks
			class UsernetForwardssh < ProxmoxAction

				def initialize app, env
					@app = app
					@logger = Log4r::Logger.new 'vagrant_proxmox::action::usernet_forwardssh'
				end

				def call env
          vm_id = env[:machine].id.split("/").last
          @logger.info "Starting..."
          connection(env).start_vm vm_id
          #connection(env).monitor_cmd vm_id, "set_link net0 off"
          
          env[:ui].info "Injecting usernet with ssh portforward..."
          connection(env).monitor_cmd vm_id, "netdev_add user,id=net1,hostfwd=tcp::#{sprintf("22%03d", vm_id.to_i).to_i}-:22"
          connection(env).monitor_cmd vm_id, "device_add virtio-net-pci,id=net1,netdev=net1,addr=0x13"
          
          env[:ui].info "Waiting for CDRom install shutdown (at least 5 minutes)..."
          
          did_stop = false
          100.times do
            sleep 5
            if connection(env).get_vm_state(vm_id) == :stopped
              did_stop = true
              break
            end
            env[:ui].info "."
          end
          
          fail "Timeout waiting for CDRom install shutdown" unless did_stop
          
          env[:ui].info "Restarting..."
          connection(env).start_vm vm_id
          connection(env).monitor_cmd vm_id, "netdev_add user,id=net1,hostfwd=tcp::#{sprintf("22%03d", vm_id.to_i).to_i}-:22"
          connection(env).monitor_cmd vm_id, "device_add virtio-net-pci,id=net1,netdev=net1,addr=0x13"
          
					next_action env
				end

			end

		end
	end
end
