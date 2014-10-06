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

  it "should persist commits as undispatched for all streams" do
    commit1 = build_commit("stream-1", "commit-1")
    commit2 = build_commit("stream-1", "commit-2")
    commit3 = build_commit("stream-2", "commit-3")

    commit_all(subject, commit1, commit2, commit3)

    undispatched = subject.get_undispatched_commits
    expect(undispatched.length).to eql(3)
    expect(undispatched[0]).to eql commit1
    expect(undispatched[1]).to eql commit2
    expect(undispatched[2]).to eql commit3
  end
  
  describe "get_from" do
    it "should return commits ordered by commit_sequence" do
      commit1 = build_commit("stream-1", "commit-1") { |c| c[:commit_sequence] = 1 }
      commit2 = build_commit("stream-1", "commit-2") { |c| c[:commit_sequence] = 2 }
      commit3 = build_commit("stream-1", "commit-3") { |c| c[:commit_sequence] = 3 }
      
      commit_all(subject, commit3, commit1, commit2)
      
      stream_commits = subject.get_from("stream-1")
      expect(stream_commits[0]).to eql commit1
      expect(stream_commits[1]).to eql commit2
      expect(stream_commits[2]).to eql commit3
    end

    it 'should retrieve commits limiting to min revision inclusive' do      
      commit1 = build_commit("stream-1", "commit-1")
      commit2 = build_commit("stream-1", "commit-2")
      commit3 = build_commit("stream-1", "commit-3")
      commit4 = build_commit("stream-1", "commit-4")

      commit_all(subject, commit1, commit2, commit3, commit4)

      stream_commits = subject.get_from("stream-1", min_revision: 3)
      expect(stream_commits.length).to eql(2)      
      expect(stream_commits[0]).to eql commit3
      expect(stream_commits[1]).to eql commit4
    end
  end
  
  describe "for_each_commit" do
    it "should iterate through all commits ordered by commit_timestamp" do
      now      = Time.now.utc
      commit11 = build_commit("stream-1", "commit-11") { |c| c[:commit_timestamp] = now - 100 }
      commit12 = build_commit("stream-1", "commit-12") { |c| c[:commit_timestamp] = now - 90 }
      commit13 = build_commit("stream-1", "commit-13") { |c| c[:commit_timestamp] = now - 80 }
      commit21 = build_commit("stream-2", "commit-21") { |c| c[:commit_timestamp] = now - 70 }
      commit22 = build_commit("stream-2", "commit-22") { |c| c[:commit_timestamp] = now - 60 }
      commit31 = build_commit("stream-3", "commit-31") { |c| c[:commit_timestamp] = now - 50 }
      commit32 = build_commit("stream-3", "commit-32") { |c| c[:commit_timestamp] = now - 40 }
      
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
  end
  
  describe "get_undispatched_commits" do
    it "should return commits ordered by commit_sequence in scope of the stream" do
      commit11 = build_commit("stream-1", "commit-11") { |c| c[:commit_sequence] = 1 }
      commit12 = build_commit("stream-1", "commit-12") { |c| c[:commit_sequence] = 2 }
      commit13 = build_commit("stream-1", "commit-13") { |c| c[:commit_sequence] = 3 }

      commit21 = build_commit("stream-2", "commit-21") { |c| c[:commit_sequence] = 1 }
      commit22 = build_commit("stream-2", "commit-22") { |c| c[:commit_sequence] = 2 }
      commit23 = build_commit("stream-2", "commit-23") { |c| c[:commit_sequence] = 3 }
      
      commit_all(subject, commit13, commit11, commit12)
      commit_all(subject, commit23, commit21, commit22)
      
      stream_commits = subject.get_undispatched_commits
      expect(stream_commits[0]).to eql commit11
      expect(stream_commits[1]).to eql commit12
      expect(stream_commits[2]).to eql commit13
      expect(stream_commits[3]).to eql commit21
      expect(stream_commits[4]).to eql commit22
      expect(stream_commits[5]).to eql commit23
    end
  end
  
  describe "commit" do
    it "should persist events" do
      commit1 = build_commit("stream-1", "commit-1", new_event("event-1"), new_event("event-2"))
      commit2 = build_commit("stream-2", "commit-2", new_event("event-1"), new_event("event-2"), new_event("event-3"))
      
      commit_all(subject, commit1, commit2)
      
      actual1 = subject.get_from("stream-1")[0]
      expect(actual1.events.length).to eql(2)
      expect(actual1.events[0]).to eql new_event("event-1")
      expect(actual1.events[1]).to eql new_event("event-2")
      
      actual2 = subject.get_from("stream-2")[0]
      expect(actual2.events.length).to eql(3)
      expect(actual2.events[0]).to eql new_event("event-1")
      expect(actual2.events[1]).to eql new_event("event-2")
      expect(actual2.events[2]).to eql new_event("event-3")
    end
      
    it "should persist headers" do
      commit1 = build_commit("stream-1", "commit-1") do |c|
        c[:headers] = {
          "header1" => "value-1",
          "header2" => "value-2",
        }
      end
      commit2 = build_commit("stream-2", "commit-2", new_event("event-1")) do |c|
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
  
  describe "mark_commit_as_dispatched" do
    it "should no longer return them with undispatched list" do
      commit1 = build_commit("stream-1", "commit-1")
      commit2 = build_commit("stream-1", "commit-2")

      commit_all(subject, commit1, commit2)
      
      #Just make sure they are initially undispatched
      expect(subject.get_undispatched_commits.length).to eql(2)
      
      subject.mark_commit_as_dispatched(commit1)
      
      undispatched = subject.get_undispatched_commits
      expect(undispatched.length).to eql(1)
      expect(undispatched).to include commit2
    end
  end  
  
  describe "purge" do
    before(:each) do
      commit1 = build_commit("stream-1", "commit-1", new_event("event-1"), new_event("event-2"))
      commit2 = build_commit("stream-2", "commit-2", new_event("event-1"), new_event("event-2"), new_event("event-3"))
      
      commit_all(subject, commit1, commit2)
      subject.purge
    end
    
    it "should remove all commits for all streams" do
      expect(subject.get_from("stream-1").length).to eql(0)
      expect(subject.get_from("stream-0").length).to eql(0)
    end
    
    it "should also remove all undispatched commits" do
      expect(subject.get_undispatched_commits.length).to eql(0)
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
end