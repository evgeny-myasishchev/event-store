require 'spec-helper'

shared_examples "generic-persistence-engine" do
  include Support::CommitsHelper
  
  it "should persist commits in different streams" do
    commit11 = build_commit("stream-1", "commit-11")
    commit12 = build_commit("stream-1", "commit-12")
    commit21 = build_commit("stream-2", "commit-21")
    commit22 = build_commit("stream-2", "commit-22")

    commit_all(subject, commit11, commit12, commit21, commit22)

    stream1_commits = subject.get_from("stream-1")
    expect(stream1_commits.length).to eql(2)
    expect(stream1_commits[0]).to eql commit11
    expect(stream1_commits[1]).to eql commit12

    stream2_commits = subject.get_from("stream-2")
    expect(stream2_commits.length).to eql(2)
    expect(stream2_commits[0]).to eql commit21
    expect(stream2_commits[1]).to eql commit22
  end

  it 'should maintain sequential checkpoint for each commit' do
    30.times do |i|
      commit_all(subject,
        build_commit('stream-1', "commit-#{i.to_s.rjust(3, '0')}"),
        build_commit('stream-2', "commit-#{i.to_s.rjust(3, '0')}"))
    end

    commits = subject.get_from('stream-1').concat(subject.get_from('stream-2')).sort_by { |c| [c.commit_id, c.stream_id] }
    commits.inject { |prev, current|
      expect(current.checkpoint).to eql prev.checkpoint.next
      current
    }
  end
  
  describe "get_from" do
    it 'should return commits ordered by checkpoint' do
      commit1 = build_commit('stream-1', 'commit-1')
      commit2 = build_commit('stream-1', 'commit-2')
      commit3 = build_commit('stream-1', 'commit-3')
      
      commit_all(subject, commit3, commit1, commit2)
      
      stream_commits = subject.get_from("stream-1")
      expect(stream_commits[0]).to eql commit3
      expect(stream_commits[1]).to eql commit1
      expect(stream_commits[2]).to eql commit2
    end

    it 'should retrieve commits limiting to min revision inclusive' do
      commit1 = build_commit('stream-1', 'commit-1')
      commit2 = build_commit('stream-1', 'commit-2')
      commit3 = build_commit('stream-1', 'commit-3')
      commit4 = build_commit('stream-1', 'commit-4')

      commit_all(subject, commit1, commit2, commit3, commit4)

      stream_commits = subject.get_from('stream-1', min_revision: 3)
      expect(stream_commits.length).to eql(2)
      expect(stream_commits[0]).to eql commit3
      expect(stream_commits[1]).to eql commit4
    end
  end
  
  describe 'get_head' do
    it 'should return head related attributes' do
      commit_all(subject, 
        build_commit("stream-1", "commit-11", "event-1", "event-2"),
        build_commit("stream-1", "commit-12", "event-3"),
        build_commit("stream-2", "commit-21", "event-1")
      )
      
      expect(subject.get_head('stream-1')).to eql(commit_sequence: 2, stream_revision: 3)
      expect(subject.get_head('stream-2')).to eql(commit_sequence: 1, stream_revision: 1)
    end
    
    it 'should return head for the new (or empty) stream' do
      expect(subject.get_head('stream-1')).to eql(commit_sequence: 0, stream_revision: 0)
    end
  end
  
  describe "for_each_commit" do
    it 'should iterate through all commits ordered by checkpoint' do
      # Basically in a order of commit itself
      
      commit11 = build_commit('stream-1', 'commit-11')
      commit12 = build_commit('stream-1', 'commit-12')
      commit13 = build_commit('stream-1', 'commit-13')
      commit21 = build_commit('stream-2', 'commit-21')
      commit22 = build_commit('stream-2', 'commit-22')
      commit31 = build_commit('stream-3', 'commit-31')
      commit32 = build_commit('stream-3', 'commit-32')
      
      commit_all(subject, commit11, commit12, commit13, commit21, commit22, commit31, commit32)
      
      all_commits = []
      subject.for_each_commit do |commit|
        all_commits << commit
      end
      
      expect(all_commits.length).to eql(7)
      expect(all_commits[0]).to eql commit11
      expect(all_commits[1]).to eql commit12
      expect(all_commits[2]).to eql commit13
      expect(all_commits[3]).to eql commit21
      expect(all_commits[4]).to eql commit22
      expect(all_commits[5]).to eql commit31
      expect(all_commits[6]).to eql commit32
    end
      
    it 'should iterate through all commits after specified checkpoint' do
      to_be_skipped = commit_all subject, *3.times.map { |i| build_commit('stream-1', "commit-1#{i}") }
      commits = [
        commit_all(subject, *3.times.map { |i| build_commit('stream-2', "commit-1#{i}") }),
        commit_all(subject, *3.times.map { |i| build_commit('stream-3', "commit-1#{i}") })
      ].flatten!
      
      fetched_commits = []
      subject.for_each_commit(checkpoint: to_be_skipped.last.checkpoint) { |c| fetched_commits << c }
      expect(fetched_commits).to eql commits
    end
  end
  
  describe "commit" do
    it "should assign checkpoint" do
      commit1 = subject.commit build_commit("stream-1", "commit-1")
      commit2 = subject.commit build_commit("stream-2", "commit-2")
      
      expect(commit1.checkpoint).not_to be_nil
      expect(commit2.checkpoint).to eql commit1.checkpoint + 1
    end

    it "should persist events" do
      commit1 = build_commit("stream-1", "commit-1", "event-1", "event-2")
      commit2 = build_commit("stream-2", "commit-2", "event-1", "event-2", "event-3")
      
      commit_all(subject, commit1, commit2)
      
      actual1 = subject.get_from("stream-1")[0]
      expect(actual1.events.length).to eql(2)
      expect(actual1.events[0]).to eql "event-1"
      expect(actual1.events[1]).to eql "event-2"
      
      actual2 = subject.get_from("stream-2")[0]
      expect(actual2.events.length).to eql(3)
      expect(actual2.events[0]).to eql "event-1"
      expect(actual2.events[1]).to eql "event-2"
      expect(actual2.events[2]).to eql "event-3"
    end
      
    it "should persist headers" do
      commit1 = build_commit("stream-1", "commit-1") do |c|
        c[:headers] = {
          "header1" => "value-1",
          "header2" => "value-2",
        }
      end
      commit2 = build_commit("stream-2", "commit-2", "event-1") do |c|
        c[:headers] = {
          "header3" => "value-3",
          "header4" => "value-4",
        }
      end
      
      commit_all(subject, commit1, commit2)
      
      actual1 = subject.get_from("stream-1")[0]
      expect(actual1.headers).to eql commit1.headers
      
      actual2 = subject.get_from("stream-2")[0]
      expect(actual2.headers).to eql commit2.headers
    end
  end 
  
  describe "purge!" do
    before(:each) do
      commit1 = build_commit("stream-1", "commit-1", "event-1", "event-2")
      commit2 = build_commit("stream-2", "commit-2", "event-1", "event-2", "event-3")
      
      commit_all(subject, commit1, commit2)
      subject.purge!
    end
    
    it "should remove all commits for all streams" do
      expect(subject.get_from("stream-1").length).to eql(0)
      expect(subject.get_from("stream-0").length).to eql(0)
    end
  end
  
  describe "exists?" do
    it "should return true if there are commits persisted for the stream" do
      commit_all(subject, build_commit("stream-1", "commit-1"))
      expect(subject.exists?('stream-1')).to be_truthy
    end
    
    it "should return false if no persisted commits for the stream" do
      expect(subject.exists?('stream-1')).to be_falsey
    end
  end
  
  describe 'transaction' do
    it 'should return value of the block if transactions are supported' do
      expect(subject).to satisfy do |s|
        if subject.supports_transactions?
          expect(subject.transaction { |t| 'return-value-133901' }).to eql 'return-value-133901'
        end
        true
      end
    end
  end
end