require "test_helper"

class TaskTest < ActiveSupport::TestCase
  # --- Valid transitions ---

  test "new task can be queued" do
    task = tasks(:new_task)
    task.queue!
    assert_equal "queued", task.stage
    assert_not_nil task.queued_at
  end

  test "queued task can be started" do
    task = tasks(:queued_task)
    task.start!
    assert_equal "in_progress", task.stage
    assert_not_nil task.started_at
  end

  test "queued task can be failed" do
    task = tasks(:queued_task)
    task.fail!("dependency missing")
    assert_equal "failed", task.stage
    assert_not_nil task.failed_at
    assert_equal "dependency missing", task.error_message
  end

  test "in_progress task can be completed" do
    task = tasks(:in_progress_task)
    task.complete!({ output: "done" })
    assert_equal "done", task.stage
    assert_not_nil task.completed_at
    assert_equal({ "output" => "done" }, task.result)
  end

  test "in_progress task can be failed" do
    task = tasks(:in_progress_task)
    task.fail!("crash")
    assert_equal "failed", task.stage
  end

  test "done task can be archived" do
    task = tasks(:done_task)
    task.archive!
    assert_equal "archived", task.stage
    assert_not_nil task.archived_at
  end

  test "failed task can be archived" do
    task = tasks(:failed_task)
    task.archive!
    assert_equal "archived", task.stage
  end

  test "failed task can be requeued" do
    task = tasks(:failed_task)
    task.queue!
    assert_equal "queued", task.stage
  end

  # --- Invalid transitions ---

  test "new task cannot be started directly" do
    task = tasks(:new_task)
    error = assert_raises(RuntimeError) { task.start! }
    assert_match(/Cannot transition from new to in_progress/, error.message)
  end

  test "new task cannot be completed" do
    task = tasks(:new_task)
    error = assert_raises(RuntimeError) { task.complete! }
    assert_match(/Cannot transition from new to done/, error.message)
  end

  test "done task cannot go back to in_progress" do
    task = tasks(:done_task)
    error = assert_raises(RuntimeError) { task.start! }
    assert_match(/Cannot transition from done to in_progress/, error.message)
  end

  test "archived task cannot transition anywhere" do
    task = tasks(:done_task)
    task.archive!
    assert_raises(RuntimeError) { task.queue! }
    assert_raises(RuntimeError) { task.start! }
    assert_raises(RuntimeError) { task.complete! }
    assert_raises(RuntimeError) { task.fail! }
  end

  # --- Slug ---

  test "slug is generated on create" do
    task = Task.create!(title: "Test slug generation")
    assert task.slug.present?
    assert task.slug.start_with?("task-")
  end

  test "slug is immutable after creation" do
    task = tasks(:new_task)
    original_slug = task.slug
    task.update!(title: "Changed title")
    assert_equal original_slug, task.slug
  end

  test "to_param returns slug" do
    task = tasks(:new_task)
    assert_equal task.slug, task.to_param
  end
end
