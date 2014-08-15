module OpenstackHandle
  class OrchestrationDelegate < DelegateClass(Fog::Orchestration::OpenStack)
    SERVICE_NAME = "Orchestration"

    def initialize(dobj, os_handle)
      super(dobj)
      @os_handle = os_handle
    end

    def stacks_for_accessible_tenants
      @os_handle.accessor_for_accessible_tenants(SERVICE_NAME, :stacks, nil)
    end
  end
end
