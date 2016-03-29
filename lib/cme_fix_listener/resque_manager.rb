module CmeFixListener
  # Given a queue name, class name, and object it will add the queue to redis,
  # and then publish the object to the given class name (within the queue).
  class ResqueManager
    def self.enqueue(account_id, msg)
      push(enqueue_item(account_id, msg))
    end

    def self.enqueue_item(account_id, msg)
      {
        'class' => ENV['REDIS_CLASS_NAME'],
        'args' => [account_id, msg]
      }.to_json
    end

    def self.push(item)
      Resque.redis.sadd('queues', ENV['REDIS_QUEUE_NAME'])
      Resque.redis.rpush("queue:#{ENV['REDIS_QUEUE_NAME']}", item)
    end
  end
end
