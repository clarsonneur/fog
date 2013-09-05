require 'fog/core/model'
require 'fog/rackspace/models/auto_scale/webhooks'

module Fog
  module Rackspace
    class AutoScale
      class Policy < Fog::Model

        # @!attribute [r] id
        # @return [String] The policy id   
      	identity :id

        # @!attribute [r] group_id
        # @return [String] The autoscale group's id
      	attribute :group_id

      	# @!attribute [r] links
        # @return [Array] Policy links
        attribute :links
      	
        # @!attribute [r] name
        # @return [String] The policy's name
        attribute :name
      	
      	# @!attribute [r] change
        # @return [Fixnum] The fixed change to the autoscale group's number of units
        attribute :change
      	
        # @!attribute [r] changePercent
        # @return [Fixnum] The percentage change to the autoscale group's number of units
        attribute :changePercent

      	# @!attribute [r] cooldown
        # @return [Fixnum] The policy's cooldown
        attribute :cooldown

      	# @!attribute [r] type
        # @note Can only be "webhook", "schedule" or "cloud_monitoring"
        # @return [String] The policy's type
        attribute :type

      	# @!attribute [r] args
        # @note An example might be:
        #
     		#	- "cron": "23 * * * *"
     		#	- "at": "2013-06-05T03:12Z"
     		#	- "check": {
    		# 	      "label": "Website check 1",
    		# 	      "type": "remote.http",
    		# 	      "details": {
    		# 	          "url": "http://www.example.com",
    		# 	          "method": "GET"
    		# 	      },
    		# 	      "monitoring_zones_poll": [
    		# 	          "mzA"
    		# 	      ],
    		# 	      "timeout": 30,
    		# 	      "period": 100,
    		# 	      "target_alias": "default"
    		# 	  },
    		# 	  "alarm_criteria": {
    		# 	       "criteria": "if (metric[\"duration\"] >= 2) { return new AlarmStatus(OK); } return new AlarmStatus(CRITICAL);"
    		# 	  }
        #
        # @return [String] Arguments used for the policy
      	attribute :args

        # @!attribute [r] desiredCapacity
        # @return [Fixnum] The desired capacity of the group
      	attribute :desiredCapacity

        # Basic sanity check to make sure attributes are valid
        #
        # @raise MissingArgumentException If no type is set
        # @raise MissingArgumentException If args attribute is missing required keys (if type == 'schedule')
		    
        # @return [Boolean] Returns true if the check passes
        def check_attributes
          raise MissingArgumentException(self.name, type) if type.nil?

        	if type == 'schedule'
        		raise MissingArgumentException(self.name, "args[cron] OR args[at]") if args['cron'].nil? && args['at'].nil?
        	end

        	true
        end

      	# Creates policy
        # * requires attributes: :name, :type, :cooldown
        # 
        # @return [Boolean] returns true if policy is being created
        #
        # @raise [Fog::Rackspace::AutoScale:::NotFound] - HTTP 404
        # @raise [Fog::Rackspace::AutoScale:::BadRequest] - HTTP 400
        # @raise [Fog::Rackspace::AutoScale:::InternalServerError] - HTTP 500
        # @raise [Fog::Rackspace::AutoScale:::ServiceError]
        #
        # @see Policies#create
        # @see http://docs-internal.rackspace.com/cas/api/v1.0/autoscale-devguide/content/POST_createPolicies_v1.0__tenantId__groups__groupId__policies_Policies.html
        def save
          requires :name, :type, :cooldown

          check_attributes

          options = {}
          options['name'] = name unless name.nil?
          options['change'] = change unless change.nil?
          options['changePercent'] = changePercent unless changePercent.nil?
          options['cooldown'] = cooldown unless cooldown.nil?
          options['type'] = type unless type.nil?
          options['desiredCapacity'] = desiredCapacity unless desiredCapacity.nil?

          if type == 'schedule'
            options['args'] = args
          end

          data = service.create_policy(group_id, options)
          merge_attributes(data.body['policies'][0])
          true
        end

      	# Updates the policy
        #
        # @return [Boolean] returns true if policy has started updating
        #
        # @raise [Fog::Rackspace::AutoScale:::NotFound] - HTTP 404
        # @raise [Fog::Rackspace::AutoScale:::BadRequest] - HTTP 400
        # @raise [Fog::Rackspace::AutoScale:::InternalServerError] - HTTP 500
        # @raise [Fog::Rackspace::AutoScale:::ServiceError]
        #
        # @see http://docs-internal.rackspace.com/cas/api/v1.0/autoscale-devguide/content/PUT_putPolicy_v1.0__tenantId__groups__groupId__policies__policyId__Policies.html
        def update
      		requires :identity

          check_attributes

      		options = {}
          options['name'] = name unless name.nil?
          options['change'] = change unless change.nil?
          options['changePercent'] = changePercent unless changePercent.nil?
          options['cooldown'] = cooldown unless cooldown.nil?
          options['type'] = type unless type.nil?
          options['desiredCapacity'] = desiredCapacity unless desiredCapacity.nil?

          if type == 'schedule'
            options['args'] = args
          end

      		data = service.update_policy(group_id, identity, options)
      		merge_attributes(data.body)
      		true
      	end

      	# Destroy the policy
        #
        # @return [Boolean] returns true if policy has started deleting
        #
        # @raise [Fog::Rackspace::AutoScale:::NotFound] - HTTP 404
        # @raise [Fog::Rackspace::AutoScale:::BadRequest] - HTTP 400
        # @raise [Fog::Rackspace::AutoScale:::InternalServerError] - HTTP 500
        # @raise [Fog::Rackspace::AutoScale:::ServiceError]
        #
        # @see http://docs-internal.rackspace.com/cas/api/v1.0/autoscale-devguide/content/DELETE_deletePolicy_v1.0__tenantId__groups__groupId__policies__policyId__Policies.html
        def destroy
      		requires :identity
      		service.delete_policy(group_id, identity)
          true
      	end

      	# Executes the scaling policy
        #
        # @return [Boolean] returns true if policy has been executed
        #
        # @raise [Fog::Rackspace::AutoScale:::NotFound] - HTTP 404
        # @raise [Fog::Rackspace::AutoScale:::BadRequest] - HTTP 400
        # @raise [Fog::Rackspace::AutoScale:::InternalServerError] - HTTP 500
        # @raise [Fog::Rackspace::AutoScale:::ServiceError]
        #
        # @see http://docs-internal.rackspace.com/cas/api/v1.0/autoscale-devguide/content/POST_executePolicy_v1.0__tenantId__groups__groupId__policies__policyId__execute_Policies.html
        def execute
      		requires :identity
      		service.execute_policy(group_id, identity)
          true
      	end

        # Gets the associated webhooks for this policy
        #
        # @return [Fog::Rackspace::AutoScale::Webhooks] returns Webhooks
        #
        # @raise [Fog::Rackspace::AutoScale:::NotFound] - HTTP 404
        # @raise [Fog::Rackspace::AutoScale:::BadRequest] - HTTP 400
        # @raise [Fog::Rackspace::AutoScale:::InternalServerError] - HTTP 500
        # @raise [Fog::Rackspace::AutoScale:::ServiceError]
        def webhooks
          data = service.list_webhooks(group_id, self.id)

          Fog::Rackspace::AutoScale::Webhooks.new({
            :service   => service,
            :policy_id => self.id,
            :group_id  => group_id
          }).merge_attributes(data.body)
        end

      end
  	end
  end
end