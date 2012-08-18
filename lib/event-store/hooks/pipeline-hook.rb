module EventStore::Hooks
  class PipelineHook
    def initialize(options = {}, &block)
      @options = {
        #Lambda that is called after the commit has been persisted
        :post_commit => block_given? ? block : lambda { |commit|  }
      }.merge! options
    end
  
    def post_commit(commit)
      @options[:post_commit].call commit
    end
  end
end