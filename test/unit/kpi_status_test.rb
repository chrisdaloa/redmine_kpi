# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::KpiStatusTest < ActiveSupport::TestCase
  def local(*args)
    Time.zone.local(*args)
  end

  def due_at
    local(2026, 7, 10, 17, 0)
  end

  def risk_at
    local(2026, 7, 10, 15, 0)
  end

  context ".for" do
    should "return :not_tracked when there is no due_at (no applicable rule)" do
      status = RedmineSla::KpiStatus.for(due_at: nil, risk_at: nil, reached_at: nil, paused: false, now: local(2026, 7, 10, 10, 0))
      assert_equal :not_tracked, status
    end

    should "return :paused when the clock is paused, regardless of timing" do
      status = RedmineSla::KpiStatus.for(due_at: due_at, risk_at: risk_at, reached_at: nil, paused: true, now: local(2026, 7, 10, 18, 0))
      assert_equal :paused, status
    end

    should "return :on_time when now is before the risk threshold" do
      status = RedmineSla::KpiStatus.for(due_at: due_at, risk_at: risk_at, reached_at: nil, paused: false, now: local(2026, 7, 10, 14, 0))
      assert_equal :on_time, status
    end

    should "return :at_risk when now is exactly at the risk threshold" do
      status = RedmineSla::KpiStatus.for(due_at: due_at, risk_at: risk_at, reached_at: nil, paused: false, now: risk_at)
      assert_equal :at_risk, status
    end

    should "return :at_risk when now is between the risk threshold and the due date" do
      status = RedmineSla::KpiStatus.for(due_at: due_at, risk_at: risk_at, reached_at: nil, paused: false, now: local(2026, 7, 10, 16, 0))
      assert_equal :at_risk, status
    end

    should "return :at_risk when now is exactly at the due date" do
      status = RedmineSla::KpiStatus.for(due_at: due_at, risk_at: risk_at, reached_at: nil, paused: false, now: due_at)
      assert_equal :at_risk, status
    end

    should "return :breached when now is after the due date" do
      status = RedmineSla::KpiStatus.for(due_at: due_at, risk_at: risk_at, reached_at: nil, paused: false, now: local(2026, 7, 10, 17, 1))
      assert_equal :breached, status
    end

    should "return :on_time when the KPI was reached before the risk threshold" do
      status = RedmineSla::KpiStatus.for(due_at: due_at, risk_at: risk_at, reached_at: local(2026, 7, 10, 14, 0), paused: false, now: local(2026, 7, 11, 9, 0))
      assert_equal :on_time, status
    end

    should "return :at_risk when the KPI was reached between the risk threshold and the due date" do
      status = RedmineSla::KpiStatus.for(due_at: due_at, risk_at: risk_at, reached_at: local(2026, 7, 10, 16, 0), paused: false, now: local(2026, 7, 11, 9, 0))
      assert_equal :at_risk, status
    end

    should "return :breached when the KPI was reached after the due date" do
      status = RedmineSla::KpiStatus.for(due_at: due_at, risk_at: risk_at, reached_at: local(2026, 7, 10, 18, 0), paused: false, now: local(2026, 7, 11, 9, 0))
      assert_equal :breached, status
    end
  end

  context ".worst" do
    should "prioritize :breached over any other status" do
      assert_equal :breached, RedmineSla::KpiStatus.worst([ :on_time, :at_risk, :breached ])
    end

    should "prioritize :at_risk over :paused, :on_time and :not_tracked" do
      assert_equal :at_risk, RedmineSla::KpiStatus.worst([ :not_tracked, :on_time, :paused, :at_risk ])
    end

    should "prioritize :paused over :on_time and :not_tracked" do
      assert_equal :paused, RedmineSla::KpiStatus.worst([ :paused, :on_time ])
    end

    should "prioritize :on_time over :not_tracked" do
      assert_equal :on_time, RedmineSla::KpiStatus.worst([ :not_tracked, :on_time ])
    end

    should "return :not_tracked when every status is :not_tracked" do
      assert_equal :not_tracked, RedmineSla::KpiStatus.worst([ :not_tracked, :not_tracked ])
    end

    should "return :not_tracked for an empty list" do
      assert_equal :not_tracked, RedmineSla::KpiStatus.worst([])
    end

    should "not depend on the order of the statuses" do
      assert_equal :breached, RedmineSla::KpiStatus.worst([ :at_risk, :breached, :paused ])
    end
  end
end
