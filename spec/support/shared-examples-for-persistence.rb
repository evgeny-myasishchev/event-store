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
    stream1_commits.should have(2).items
    stream1_commits[0].should eql commit11
    stream1_commits[1].should eql commit12

    stream2_commits = subject.get_from("stream-2")
    stream2_commits.should have(2).items
    stream2_commits[0].should eql commit21
    stream2_commits[1].should eql commit22
  end

  it "should persist commits as undispatched for all streams" do
    commit1 = build_commit("stream-1", "commit-1")
    commit2 = build_commit("stream-1", "commit-2")
    commit3 = build_commit("stream-2", "commit-3")

    commit_all(subject, commit1, commit2, commit3)

    undispatched = subject.get_undispatched_commits
    undispatched.should have(3).items
    undispatched[0].should eql commit1
    undispatched[1].should eql commit2
    undispatched[2].should eql commit3
  end
  
  describe "get_from" do
    it "should return commits ordered by commit_sequence" do
      commit1 = build_commit("stream-1", "commit-1") { |c| c[:commit_sequence] = 1 }
      commit2 = build_commit("stream-1", "commit-2") { |c| c[:commit_sequence] = 2 }
      commit3 = build_commit("stream-1", "commit-3") { |c| c[:commit_sequence] = 3 }
      
      commit_all(subject, commit3, commit1, commit2)
      
      stream_commits = subject.get_from("stream-1")
      stream_commits[0].should eql commit1
      stream_commits[1].should eql commit2
      stream_commits[2].should eql commit3
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
      
      all_commits.should have(7).items
      all_commits[0].should eql commit11
      all_commits[1].should eql commit12
      all_commits[2].should eql commit13
      all_commits[3].should eql commit21
      all_commits[4].should eql commit22
      all_commits[5].should eql commit31
      all_commits[6].should eql commit32
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
      stream_commits[0].should eql commit11
      stream_commits[1].should eql commit12
      stream_commits[2].should eql commit13
      stream_commits[3].should eql commit21
      stream_commits[4].should eql commit22
      stream_commits[5].should eql commit23
    end
  end
  
  describe "commit" do
    it "should persist events" do
      commit1 = build_commit("stream-1", "commit-1", new_event("event-1"), new_event("event-2"))
      commit2 = build_commit("stream-2", "commit-2", new_event("event-1"), new_event("event-2"), new_event("event-3"))
      
      commit_all(subject, commit1, commit2)
      
      actual1 = subject.get_from("stream-1")[0]
      actual1.events.should have(2).items
      actual1.events[0].should eql new_event("event-1")
      actual1.events[1].should eql new_event("event-2")
      
      actual2 = subject.get_from("stream-2")[0]
      actual2.events.should have(3).items
      actual2.events[0].should eql new_event("event-1")
      actual2.events[1].should eql new_event("event-2")
      actual2.events[2].should eql new_event("event-3")
    end
  end
  
  describe "mark_commit_as_dispatched" do
    it "should no longer return them with undispatched list" do
      commit1 = build_commit("stream-1", "commit-1")
      commit2 = build_commit("stream-1", "commit-2")

      commit_all(subject, commit1, commit2)
      
      #Just make sure they are initially undispatched
      subject.get_undispatched_commits.should have(2).items
      
      subject.mark_commit_as_dispatched(commit1)
      
      undispatched = subject.get_undispatched_commits
      undispatched.should have(1).items
      undispatched.should include commit2
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
      subject.get_from("stream-1").should have(0).items
      subject.get_from("stream-0").should have(0).items
    end
    
    it "should also remove all undispatched commits" do
      subject.get_undispatched_commits.should have(0).items
    end
  end
  
  describe "exists?" do
    it "should return true if there are commits persisted for the stream" do
      commit_all(subject, build_commit("stream-1", "commit-1"))
      subject.exists?('stream-1').should be_true
    end
    
    it "should return false if no persisted commits for the stream" do
      subject.exists?('stream-1').should be_false
    end
  end
end