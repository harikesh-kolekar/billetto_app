class AddVoteCountsToEvents < ActiveRecord::Migration[8.1]
  def up
    add_column :events, :upvotes, :integer, null: false, default: 0
    add_column :events, :downvotes, :integer, null: false, default: 0

    execute <<~SQL
      UPDATE events
      SET upvotes = votes.upvotes, downvotes = votes.downvotes
      FROM (
        SELECT event_id,
          COUNT(*) FILTER (WHERE vote_type = 'EventUpvoted') AS upvotes,
          COUNT(*) FILTER (WHERE vote_type = 'EventDownvoted') AS downvotes
        FROM event_votes
        GROUP BY event_id
      ) AS votes
      WHERE events.id = votes.event_id
    SQL
  end

  def down
    remove_column :events, :upvotes
    remove_column :events, :downvotes
  end
end
