# frozen_string_literal: true

module Geet
  module Git
    # This class represents, for convenience, both the local and the remote repository, but the
    # remote code is separated in each provider module.
    class Repository
      # For simplicity, we match any character except the ones the separators.
      REMOTE_ORIGIN_REGEX = %r{
        \A
        (?:https://(.+?)/|git@(.+?):)
        ([^/]+/.*?)
        (?:\.git)?
        \Z
      }x

      ORIGIN_NAME   = 'origin'
      UPSTREAM_NAME = 'upstream'

      def initialize(api_token, upstream: false)
        @api_token = api_token
        @upstream = upstream
      end

      # REMOTE FUNCTIONALITIES (REPOSITORY)

      def collaborators
        provider_module::Collaborator.list(api_helper)
      end

      def labels
        provider_module::Label.list(api_helper)
      end

      def create_gist(filename, content, description: nil, publik: false)
        provider_module::Gist.create(filename, content, api_helper, description: description, publik: publik)
      end

      def create_issue(title, description)
        provider_module::Issue.create(title, description, api_helper)
      end

      def abstract_issues(milestone: nil)
        provider_module::AbstractIssue.list(api_helper, milestone: milestone)
      end

      def issues
        provider_module::Issue.list(api_helper)
      end

      def milestone(number)
        provider_module::Milestone.find(number, api_helper)
      end

      def milestones
        provider_module::Milestone.list(api_helper)
      end

      def create_pr(title, description, head)
        provider_module::PR.create(title, description, head, api_helper)
      end

      def prs(head: nil)
        provider_module::PR.list(api_helper, head: head)
      end

      # REMOTE FUNCTIONALITIES (ACCOUNT)

      def authenticated_user
        provider_module::Account.new(api_helper).authenticated_user
      end

      # OTHER/CONVENIENCE FUNCTIONALITIES

      def current_branch
        branch = `git rev-parse --abbrev-ref HEAD`.strip

        raise "Couldn't find current branch" if branch == 'HEAD'

        branch
      end

      private

      # REPOSITORY METADATA

      # The result is in the format `git@github.com:saveriomiroddi/geet.git`
      #
      def remote(name)
        remote_url = `git ls-remote --get-url #{name}`.strip

        if remote_url == name
          raise "Remote #{name.inspect} not found!"
        elsif remote_url !~ REMOTE_ORIGIN_REGEX
          raise "Unexpected remote reference format: #{remote_url.inspect}"
        end

        remote_url
      end

      # PROVIDER

      def provider_domain
        # We assume that it's not possible to have origin and upstream on different providers.
        #
        remote_url = remote(ORIGIN_NAME)

        domain = remote_url[REMOTE_ORIGIN_REGEX, 1] || remote_url[REMOTE_ORIGIN_REGEX, 2]

        raise "Can't identify domain in the provider domain string: #{provider_domain}" if domain !~ /(.*)\.\w+/

        domain
      end

      def provider_module
        module_name = provider_domain[/(.*)\.\w+/, 1].capitalize

        require_provider_modules

        Kernel.const_get("Geet::#{module_name}")
      end

      def require_provider_modules
        provider_dirname = provider_domain[/(.*)\.\w+/, 1]
        files_pattern = "#{__dir__}/../#{provider_dirname}/*.rb"

        Dir[files_pattern].each { |filename| require filename }
      end

      # OTHER HELPERS

      def api_helper
        provider_module::ApiHelper.new(@api_token, path(upstream: @upstream), @upstream)
      end

      # Example: `saveriomiroddi/geet`
      #
      def path(upstream: false)
        remote_name = upstream ? UPSTREAM_NAME : ORIGIN_NAME

        remote(remote_name)[REMOTE_ORIGIN_REGEX, 3]
      end
    end
  end
end
