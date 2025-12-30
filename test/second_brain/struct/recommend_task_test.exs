defmodule SecondBrain.Struct.RecommendTaskTest do
  use ExUnit.Case, async: true

  alias SecondBrain.Struct.{RecommendTask, Task, TaskSchedule, WorkSession}

  @cur_ts ~U[2025-12-15 00:00:00Z]

  # Set up
  # Current timestamp ~U[2025-12-15 00:00:00Z]
  # Week 1 : ~U[2025-12-01 00:00:00Z] ~U[2025-12-08 00:00:00Z]
  # Week 0 : ~U[2025-12-08 00:00:00Z] ~U[2025-12-15 00:00:00Z]
  #
  # Task 1 : one block in Week 1,
  #          one block across Week 1 and Week 0
  #          two block in Week 0,
  # Task 2 : one block in Week 1,
  #          Desire change
  #          two block in Week 0,
  #          Desire change between the two blocks
  # Task 3 : no block, desire is non zero
  # Task 4 : no block, desire is zero
  # Task 5 : one block in Week 1
  #          Week 0 desire changed to zero

  defp task1 do
    %Task{
      task_name: "Task 1",
      schedules: [
        %TaskSchedule{
          start_at: ~U[2025-12-01 00:00:00Z],
          end_at: nil,
          hours_per_week: 10.0
        }
      ]
    }
  end

  defp task1_sessions do
    [
      %WorkSession{
        task_name: "Task 1",
        start_ts: ~U[2025-12-03 10:00:00Z],
        end_ts: ~U[2025-12-03 13:00:00Z]
      },
      %WorkSession{
        task_name: "Task 1",
        start_ts: ~U[2025-12-07 23:00:00Z],
        end_ts: ~U[2025-12-08 01:00:00Z]
      },
      %WorkSession{
        task_name: "Task 1",
        start_ts: ~U[2025-12-09 01:00:00Z],
        end_ts: ~U[2025-12-09 02:00:00Z]
      },
      %WorkSession{
        task_name: "Task 1",
        start_ts: ~U[2025-12-12 02:00:00Z],
        end_ts: ~U[2025-12-12 03:30:00Z]
      }
    ]
  end

  defp task2 do
    %Task{
      task_name: "Task 2",
      schedules: [
        %TaskSchedule{
          start_at: ~U[2025-12-12 00:00:00Z],
          end_at: nil,
          hours_per_week: 7.0
        },
        %TaskSchedule{
          start_at: ~U[2025-12-04 00:00:00Z],
          end_at: ~U[2025-12-12 00:00:00Z],
          hours_per_week: 8.0
        },
        %TaskSchedule{
          start_at: ~U[2025-12-01 00:00:00Z],
          end_at: ~U[2025-12-04 00:00:00Z],
          hours_per_week: 10.0
        }
      ]
    }
  end

  defp task2_sessions do
    [
      %WorkSession{
        task_name: "Task 2",
        start_ts: ~U[2025-12-13 00:00:00Z],
        end_ts: ~U[2025-12-13 01:00:00Z]
      },
      %WorkSession{
        task_name: "Task 2",
        start_ts: ~U[2025-12-10 08:00:00Z],
        end_ts: ~U[2025-12-10 12:00:00Z]
      },
      %WorkSession{
        task_name: "Task 2",
        start_ts: ~U[2025-12-02 10:00:00Z],
        end_ts: ~U[2025-12-02 12:00:00Z]
      }
    ]
  end

  defp task3 do
    %Task{
      task_name: "Task 3",
      schedules: [
        %TaskSchedule{
          start_at: ~U[2025-12-01 00:00:00Z],
          end_at: nil,
          hours_per_week: 0.0
        }
      ]
    }
  end

  defp task3_sessions do
    []
  end

  defp task4 do
    %Task{
      task_name: "Task 4",
      schedules: [
        %TaskSchedule{
          start_at: ~U[2025-12-01 00:00:00Z],
          end_at: nil,
          hours_per_week: 0.0
        }
      ]
    }
  end

  defp task4_sessions do
    []
  end

  defp task5 do
    %Task{
      task_name: "Task 5",
      schedules: [
        %TaskSchedule{
          start_at: ~U[2025-12-09 00:00:00Z],
          end_at: nil,
          hours_per_week: 0.0
        },
        %TaskSchedule{
          start_at: ~U[2025-12-01 00:00:00Z],
          end_at: ~U[2025-12-09 00:00:00Z],
          hours_per_week: 5.0
        }
      ]
    }
  end

  defp task5_sessions do
    [
      %WorkSession{
        task_name: "Task 5",
        start_ts: ~U[2025-12-03 16:00:00Z],
        end_ts: ~U[2025-12-03 18:00:00Z]
      }
    ]
  end

  defp setup_tasks do
    [
      task1(),
      task2(),
      task3(),
      task4(),
      task5()
    ]
  end

  defp setup_sessions do
    [
      task1_sessions(),
      task2_sessions(),
      task3_sessions(),
      task4_sessions(),
      task5_sessions()
    ]
    |> List.flatten()
    |> Enum.sort_by(& &1.start_ts, :desc)
  end

  # Entry point

  describe "recommend_by_history" do
    test "Basic Setup" do
      tasks = setup_tasks()
      sessions = setup_sessions()

      {:ok, recommendations} = RecommendTask.recommend_by_history(tasks, sessions, @cur_ts)

      assert recommendations == [
               %SecondBrain.Struct.RecommendTask{
                 task_name: "Task 1",
                 desired_effort: 10.0,
                 current_percent_effort: 33.3,
                 last_session: %SecondBrain.Struct.WorkSession{
                   account_id: nil,
                   task_name: "Task 1",
                   start_ts: ~U[2025-12-12 02:00:00Z],
                   end_ts: ~U[2025-12-12 03:30:00Z],
                   notes: nil
                 }
               },
               %SecondBrain.Struct.RecommendTask{
                 task_name: "Task 2",
                 desired_effort: 7.0,
                 current_percent_effort: 51.6,
                 last_session: %SecondBrain.Struct.WorkSession{
                   account_id: nil,
                   task_name: "Task 2",
                   start_ts: ~U[2025-12-13 00:00:00Z],
                   end_ts: ~U[2025-12-13 01:00:00Z],
                   notes: nil
                 }
               }
             ]
    end

    test "limit only 1 return" do
      tasks = setup_tasks()
      sessions = setup_sessions()

      {:ok, recommendations} =
        RecommendTask.recommend_by_history(tasks, sessions, @cur_ts, limit_n: 1)

      assert recommendations == [
               %SecondBrain.Struct.RecommendTask{
                 task_name: "Task 1",
                 desired_effort: 10.0,
                 current_percent_effort: 33.3,
                 last_session: %SecondBrain.Struct.WorkSession{
                   account_id: nil,
                   task_name: "Task 1",
                   start_ts: ~U[2025-12-12 02:00:00Z],
                   end_ts: ~U[2025-12-12 03:30:00Z],
                   notes: nil
                 }
               }
             ]
    end

    test "empty" do
      tasks = setup_tasks()
      sessions = setup_sessions()
      cur_ts = DateTime.utc_now()

      assert {:ok, []} = RecommendTask.recommend_by_history([], sessions, cur_ts)

      assert {:ok,
              [
                %RecommendTask{
                  task_name: "Task 1",
                  current_percent_effort: 0.0,
                  desired_effort: 10.0
                },
                %RecommendTask{
                  task_name: "Task 2",
                  current_percent_effort: 0.0,
                  desired_effort: 7.0
                }
              ]} = RecommendTask.recommend_by_history(tasks, [], cur_ts)
    end
  end

  # Complex Helper function

  describe "percent_effort_by_task_by_week" do
    test "Basic Setup" do
      tasks = setup_tasks()
      sessions = setup_sessions()
      sessions_by_week = WorkSession.split_by_week(sessions, @cur_ts)

      result = RecommendTask.percent_effort_by_task_by_week(tasks, sessions_by_week)

      assert result == %{
               0 => %{
                 "Task 1" => 25.0,
                 "Task 2" => 66.0377358490566,
                 "Task 3" => 0.0,
                 "Task 4" => 0,
                 "Task 5" => 0.0
               },
               1 => %{
                 "Task 1" => 50.0,
                 "Task 2" => 22.58064516129032,
                 "Task 3" => 0.0,
                 "Task 4" => 0,
                 "Task 5" => 40.0
               }
             }
    end
  end

  # Helper Functions

  describe "get_desired_effort_by_task/1" do
    test "handles active schedule with end_at = nil" do
      schedules = [
        %TaskSchedule{hours_per_week: 3.0, start_at: ~U[2025-12-22 00:00:00Z], end_at: nil}
      ]

      tasks = [%Task{task_name: "Active Task", schedules: schedules}]
      result = RecommendTask.get_desired_effort_by_task(tasks)
      assert result == %{"Active Task" => 3.0}
    end

    test "returns a map of task names to hours per week when schedule present" do
      tasks = [
        %Task{task_name: "Task 1", schedules: [%TaskSchedule{hours_per_week: 5.0}]},
        %Task{
          task_name: "Task 2",
          schedules: [%TaskSchedule{hours_per_week: 2.5}, %TaskSchedule{hours_per_week: 5.0}]
        }
      ]

      result = RecommendTask.get_desired_effort_by_task(tasks)
      assert result == %{"Task 1" => 5.0, "Task 2" => 2.5}
    end

    test "returns 0.0 for tasks with no schedule or empty schedule" do
      tasks = [
        %Task{task_name: "Task 3", schedules: []},
        %Task{task_name: "Task 4", schedules: nil},
        # no hours_per_week
        %Task{task_name: "Task 5", schedules: [%TaskSchedule{}]}
      ]

      result = RecommendTask.get_desired_effort_by_task(tasks)
      assert result == %{"Task 3" => 0.0, "Task 4" => 0.0, "Task 5" => 0.0}
    end
  end

  describe "get_last_session_by_task/1" do
    alias SecondBrain.Struct.WorkSession

    test "returns empty map when session history is empty" do
      assert RecommendTask.get_last_session_by_task([]) == %{}
    end

    test "returns map with last session for each task" do
      dt1 = ~U[2025-12-28 10:00:00Z]
      dt2 = ~U[2025-12-28 11:00:00Z]
      dt3 = ~U[2025-12-28 12:00:00Z]
      session1 = %WorkSession{task_name: "Task A", start_ts: dt2, end_ts: dt3}
      session2 = %WorkSession{task_name: "Task B", start_ts: dt2, end_ts: dt3}
      session3 = %WorkSession{task_name: "Task A", start_ts: dt1, end_ts: dt2}

      # session1 and session3 have same task_name, session1 should be kept (first occurrence)
      sessions = [session1, session2, session3]
      result = RecommendTask.get_last_session_by_task(sessions)
      assert result["Task A"] == session1
      assert result["Task B"] == session2
      assert map_size(result) == 2
    end
  end

  describe "sum_effort_level_by_task/2" do
    test "returns empty map when session history is empty" do
      assert RecommendTask.sum_effort_level_by_task([], nil) == %{}
    end

    test "returns correct effort for single session" do
      dt1 = ~U[2025-12-28 10:00:00Z]
      dt2 = ~U[2025-12-28 12:00:00Z]
      session = %WorkSession{task_name: "Task X", start_ts: dt1, end_ts: dt2}
      result = RecommendTask.sum_effort_level_by_task([session], nil)
      # 2 hours
      assert result == %{"Task X" => 2.0}
    end

    test "returns summed effort for multiple sessions of same task" do
      dt1 = ~U[2025-12-28 10:00:00Z]
      dt2 = ~U[2025-12-28 12:00:00Z]
      dt3 = ~U[2025-12-28 13:00:00Z]
      dt4 = ~U[2025-12-28 15:00:00Z]
      session1 = %WorkSession{task_name: "Task Y", start_ts: dt1, end_ts: dt2}
      session2 = %WorkSession{task_name: "Task Y", start_ts: dt3, end_ts: dt4}
      result = RecommendTask.sum_effort_level_by_task([session1, session2], nil)
      # 2 + 2 = 4 hours
      assert result == %{"Task Y" => 4.0}
    end

    test "returns correct effort for multiple tasks" do
      dt1 = ~U[2025-12-28 10:00:00Z]
      dt2 = ~U[2025-12-28 12:00:00Z]
      dt3 = ~U[2025-12-28 13:00:00Z]
      dt4 = ~U[2025-12-28 15:23:00Z]
      session1 = %WorkSession{task_name: "Task Z", start_ts: dt1, end_ts: dt2}
      session2 = %WorkSession{task_name: "Task W", start_ts: dt3, end_ts: dt4}
      result = RecommendTask.sum_effort_level_by_task([session1, session2], nil)
      assert result == %{"Task Z" => 2.0, "Task W" => 2.4}
    end
  end

  describe "calculate_desired_effort_one_week_one_task/2" do
    test "active schedule with end_at = nil overlaps week" do
      week_start = ~U[2025-12-22 00:00:00Z]
      week_end = ~U[2025-12-29 00:00:00Z]
      schedule = %TaskSchedule{start_at: week_start, end_at: nil, hours_per_week: 5.0}
      task = %Task{task_name: "Active Task", schedules: [schedule]}
      # Should treat as overlapping the week
      result =
        RecommendTask.calculate_desired_effort_one_week_one_task(task, {week_start, week_end})

      assert result > 0
    end

    test "returns 0 if no schedules" do
      task = %Task{task_name: "Task1", schedules: []}
      week_start = ~U[2025-12-22 00:00:00Z]
      week_end = ~U[2025-12-29 00:00:00Z]

      result =
        RecommendTask.calculate_desired_effort_one_week_one_task(task, {week_start, week_end})

      assert result == 0
    end

    test "returns 0 if no overlap with week" do
      schedule = %TaskSchedule{
        start_at: ~U[2025-12-10 00:00:00Z],
        end_at: ~U[2025-12-11 00:00:00Z],
        hours_per_week: 10.0
      }

      task = %Task{task_name: "Task2", schedules: [schedule]}
      week_start = ~U[2025-12-22 00:00:00Z]
      week_end = ~U[2025-12-29 00:00:00Z]

      result =
        RecommendTask.calculate_desired_effort_one_week_one_task(task, {week_start, week_end})

      assert result == 0
    end

    test "returns full effort if schedule fully overlaps week" do
      schedule = %TaskSchedule{
        start_at: ~U[2025-12-22 00:00:00Z],
        end_at: ~U[2025-12-30 00:00:00Z],
        hours_per_week: 7.0
      }

      task = %Task{task_name: "Task3", schedules: [schedule]}
      week_start = ~U[2025-12-22 00:00:00Z]
      week_end = ~U[2025-12-29 00:00:00Z]

      result =
        RecommendTask.calculate_desired_effort_one_week_one_task(task, {week_start, week_end})

      assert_in_delta result, 7.0, 0.0001
    end

    test "returns proportional effort if schedule partially overlaps week" do
      # Schedule overlaps only 1 day of the week (1/7th)
      schedule = %TaskSchedule{
        start_at: ~U[2025-12-28 00:00:00Z],
        end_at: ~U[2025-12-29 00:00:00Z],
        hours_per_week: 7.0
      }

      task = %Task{task_name: "Task4", schedules: [schedule]}
      week_start = ~U[2025-12-22 00:00:00Z]
      week_end = ~U[2025-12-29 00:00:00Z]

      result =
        RecommendTask.calculate_desired_effort_one_week_one_task(task, {week_start, week_end})

      # 1/7th of 7.0 is 1.0
      assert_in_delta result, 1.0, 0.01
    end
  end

  describe "split_by_week" do
    test "setup test" do
      sessions = setup_sessions()
      sessions_by_week = WorkSession.split_by_week(sessions, @cur_ts)

      assert sessions_by_week == %{
               {0, {~U[2025-12-08 00:00:00Z], ~U[2025-12-15 00:00:00Z]}} => [
                 %SecondBrain.Struct.WorkSession{
                   account_id: nil,
                   end_ts: ~U[2025-12-13 01:00:00Z],
                   notes: nil,
                   start_ts: ~U[2025-12-13 00:00:00Z],
                   task_name: "Task 2"
                 },
                 %SecondBrain.Struct.WorkSession{
                   account_id: nil,
                   end_ts: ~U[2025-12-12 03:30:00Z],
                   notes: nil,
                   start_ts: ~U[2025-12-12 02:00:00Z],
                   task_name: "Task 1"
                 },
                 %SecondBrain.Struct.WorkSession{
                   account_id: nil,
                   end_ts: ~U[2025-12-10 12:00:00Z],
                   notes: nil,
                   start_ts: ~U[2025-12-10 08:00:00Z],
                   task_name: "Task 2"
                 },
                 %SecondBrain.Struct.WorkSession{
                   account_id: nil,
                   end_ts: ~U[2025-12-09 02:00:00Z],
                   notes: nil,
                   start_ts: ~U[2025-12-09 01:00:00Z],
                   task_name: "Task 1"
                 }
               ],
               {1, {~U[2025-12-01 00:00:00Z], ~U[2025-12-08 00:00:00Z]}} => [
                 %SecondBrain.Struct.WorkSession{
                   account_id: nil,
                   end_ts: ~U[2025-12-08 01:00:00Z],
                   notes: nil,
                   start_ts: ~U[2025-12-07 23:00:00Z],
                   task_name: "Task 1"
                 },
                 %SecondBrain.Struct.WorkSession{
                   account_id: nil,
                   end_ts: ~U[2025-12-03 18:00:00Z],
                   notes: nil,
                   start_ts: ~U[2025-12-03 16:00:00Z],
                   task_name: "Task 5"
                 },
                 %SecondBrain.Struct.WorkSession{
                   account_id: nil,
                   end_ts: ~U[2025-12-03 13:00:00Z],
                   notes: nil,
                   start_ts: ~U[2025-12-03 10:00:00Z],
                   task_name: "Task 1"
                 },
                 %SecondBrain.Struct.WorkSession{
                   account_id: nil,
                   end_ts: ~U[2025-12-02 12:00:00Z],
                   notes: nil,
                   start_ts: ~U[2025-12-02 10:00:00Z],
                   task_name: "Task 2"
                 }
               ]
             }
    end
  end

  describe "combined_percent_effort_by_task/1" do
    test "returns empty map when input is empty" do
      result = RecommendTask.combined_percent_effort_by_task(%{})
      assert result == %{}
    end

    test "returns same effort when only one week present" do
      # Single week should not be scaled
      percent_effort_by_week = %{
        0 => %{
          "Task 1" => 80.0,
          "Task 2" => 100.0,
          "Task 3" => 120.0
        }
      }

      result = RecommendTask.combined_percent_effort_by_task(percent_effort_by_week)

      # With only week 0, scaling factor is 1.0, so result should be unchanged
      assert_in_delta result["Task 1"], 80.0, 0.01
      assert_in_delta result["Task 2"], 100.0, 0.01
      assert_in_delta result["Task 3"], 120.0, 0.01
    end

    test "combines efforts from multiple weeks with exponential weighting" do
      # Week 0 (scaling factor = 1.0) and Week 1 (scaling factor = 0.5)
      percent_effort_by_week = %{
        0 => %{
          "Task 1" => 100.0,
          "Task 2" => 80.0
        },
        1 => %{
          "Task 1" => 60.0,
          "Task 2" => 100.0
        }
      }

      result = RecommendTask.combined_percent_effort_by_task(percent_effort_by_week)

      # Scaling factors: week 0 = 1.0, week 1 = 0.5, total = 1.5
      # Task 1: (100.0 * 1.0 + 60.0 * 0.5) / 1.5 = (100.0 + 30.0) / 1.5 = 86.67
      # Task 2: (80.0 * 1.0 + 100.0 * 0.5) / 1.5 = (80.0 + 50.0) / 1.5 = 86.67
      assert_in_delta result["Task 1"], 86.67, 0.1
      assert_in_delta result["Task 2"], 86.67, 0.1
    end

    test "handles three weeks with exponential decay" do
      percent_effort_by_week = %{
        0 => %{"Task 1" => 100.0},
        1 => %{"Task 1" => 100.0},
        2 => %{"Task 1" => 100.0}
      }

      result = RecommendTask.combined_percent_effort_by_task(percent_effort_by_week)

      # Scaling factors: week 0 = 1.0, week 1 = 0.5, week 2 = 0.25, total = 1.75
      # Task 1: (100.0 * 1.0 + 100.0 * 0.5 + 100.0 * 0.25) / 1.75 = 175 / 1.75 = 100
      assert_in_delta result["Task 1"], 100.0, 0.1
    end

    test "handles tasks that appear in only some weeks" do
      percent_effort_by_week = %{
        0 => %{
          "Task 1" => 100.0,
          "Task 2" => 80.0
        },
        1 => %{
          "Task 1" => 60.0,
          "Task 3" => 50.0
        }
      }

      result = RecommendTask.combined_percent_effort_by_task(percent_effort_by_week)

      # All three tasks should be in result
      assert Map.has_key?(result, "Task 1")
      assert Map.has_key?(result, "Task 2")
      assert Map.has_key?(result, "Task 3")

      # Scaling factors: week 0 = 1.0, week 1 = 0.5, total = 1.5
      # Task 1: (100.0 * 1.0 + 60.0 * 0.5) / 1.5 = 86.67
      # Task 2: (80.0 * 1.0 + 0 * 0.5) / 1.5 = 53.33
      # Task 3: (0 * 1.0 + 50.0 * 0.5) / 1.5 = 16.67
      assert_in_delta result["Task 1"], 86.67, 0.1
      assert_in_delta result["Task 2"], 53.33, 0.1
      assert_in_delta result["Task 3"], 16.67, 0.1
    end

    test "handles zero percent efforts" do
      percent_effort_by_week = %{
        0 => %{
          "Task 1" => 0.0,
          "Task 2" => 100.0
        },
        1 => %{
          "Task 1" => 50.0,
          "Task 2" => 0.0
        }
      }

      result = RecommendTask.combined_percent_effort_by_task(percent_effort_by_week)

      # Scaling factors: week 0 = 1.0, week 1 = 0.5, total = 1.5
      # Task 1: (0.0 * 1.0 + 50.0 * 0.5) / 1.5 = 16.67
      # Task 2: (100.0 * 1.0 + 0.0 * 0.5) / 1.5 = 66.67
      assert_in_delta result["Task 1"], 16.67, 0.1
      assert_in_delta result["Task 2"], 66.67, 0.1
    end

    test "handles high effort values exceeding 100%" do
      percent_effort_by_week = %{
        0 => %{
          "Task 1" => 200.0,
          "Task 2" => 150.0
        },
        1 => %{
          "Task 1" => 175.0,
          "Task 2" => 180.0
        }
      }

      result = RecommendTask.combined_percent_effort_by_task(percent_effort_by_week)

      # Scaling factors: week 0 = 1.0, week 1 = 0.5, total = 1.5
      # Task 1: (200.0 * 1.0 + 175.0 * 0.5) / 1.5 = 287.5 / 1.5 = 191.67
      # Task 2: (150.0 * 1.0 + 180.0 * 0.5) / 1.5 = 240.0 / 1.5 = 160.0
      assert_in_delta result["Task 1"], 191.67, 0.1
      assert_in_delta result["Task 2"], 160.0, 0.1
    end

    test "result values are all non-negative" do
      percent_effort_by_week = %{
        0 => %{
          "Task 1" => 50.0,
          "Task 2" => 75.0,
          "Task 3" => 0.0
        },
        1 => %{
          "Task 1" => 25.0,
          "Task 2" => 100.0,
          "Task 3" => 50.0
        },
        2 => %{
          "Task 1" => 10.0,
          "Task 2" => 20.0,
          "Task 3" => 0.0
        }
      }

      result = RecommendTask.combined_percent_effort_by_task(percent_effort_by_week)

      Enum.each(result, fn {_task_name, percent} ->
        assert percent >= 0.0, "Expected non-negative percent effort"
      end)
    end
  end
end
