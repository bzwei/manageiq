#
# Description: This method updates the service provision status.
# Required inputs: status
#

prov = $evm.root['service_template_provision_task']

unless prov
  $evm.log(:error, "Service Template Provision Task not provided")
  exit(MIQ_STOP)
end

# Get status from input field status
status = $evm.inputs['status']

# Update Status Message
updated_message  = "Server [#{$evm.root['miq_server'].name}]\n"
updated_message += "Service [#{prov.destination.name}]\n"
updated_message += "Step [#{$evm.root['ae_state']}]\n"
updated_message += "Status [#{status}]\n"
updated_message += "Message [#{prov.message}]\n"
updated_message += "Current Retry Number [#{$evm.root['ae_state_retries']}]" if $evm.root['ae_result'] == 'retry'
prov.miq_request.user_message = updated_message
prov.message = status
