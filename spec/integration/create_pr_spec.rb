# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/geet/git/repository'
require_relative '../../lib/geet/services/create_pr'

describe Geet::Services::CreatePr do
  let(:git_client) { Geet::Utils::GitClient.new }
  let(:repository) { Geet::Git::Repository.new(git_client: git_client) }
  let(:upstream_repository) { Geet::Git::Repository.new(upstream: true, git_client: git_client) }

  context 'with labels, reviewers and milestones' do
    it 'should create a PR' do
      allow(git_client).to receive(:current_branch).and_return('mybranch1')
      allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo')

      expected_output = <<~STR
        Finding labels...
        Finding milestone...
        Finding collaborators...
        Creating PR...
        Assigning authenticated user...
        Adding labels other_bug, invalid...
        Setting milestone 0.0.1...
        Requesting review from donald-ts, donald-fr...
        PR address: https://github.com/donaldduck/testrepo/pull/3
      STR

      actual_output = StringIO.new

      actual_created_pr = VCR.use_cassette('create_pr') do
        service_instance = described_class.new(repository, git_client: git_client)
        service_instance.execute(
          'Title', 'Description',
          label_patterns: '_bug,invalid', milestone_pattern: '0.0.1', reviewer_patterns: 'nald-ts,nald-fr',
          no_open_pr: true, output: actual_output
        )
      end

      expect(actual_output.string).to eql(expected_output)

      expect(actual_created_pr.number).to eql(3)
      expect(actual_created_pr.title).to eql('Title')
      expect(actual_created_pr.link).to eql('https://github.com/donaldduck/testrepo/pull/3')
    end
  end

  it 'should create an upstream PR' do
    allow(git_client).to receive(:current_branch).and_return('mybranch')
    allow(git_client).to receive(:remote).with('origin').and_return('git@github.com:donaldduck/testrepo_2f')
    allow(git_client).to receive(:remote).with('upstream').and_return('git@github.com:donald-fr/testrepo_u')

    expected_output = <<~STR
      Creating PR...
      Assigning authenticated user...
      PR address: https://github.com/donald-fr/testrepo_u/pull/4
    STR

    actual_output = StringIO.new

    actual_created_pr = VCR.use_cassette('create_pr_upstream') do
      service_instance = described_class.new(upstream_repository, git_client: git_client)
      service_instance.execute('Title', 'Description', no_open_pr: true, output: actual_output)
    end

    expect(actual_output.string).to eql(expected_output)

    expect(actual_created_pr.number).to eql(4)
    expect(actual_created_pr.title).to eql('Title')
    expect(actual_created_pr.link).to eql('https://github.com/donald-fr/testrepo_u/pull/4')
  end
end
