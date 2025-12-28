# SecondBrain

## Database Model

```
account
  id
  name
  email
  google_sub

brain_cache
  account_id
  last_session_task_name
  last_session_start_ts
  last_session_end_ts     // != nil means idle
  last_session_notes

brain_disk_s3
  account_id
  file_name
  file_entry_cnt
  seq_1

TODO

account_setting
  account_id
  phone_number

brain_config
  account_id
  sleep
```

## Backup Model

`task.json`
```
[
  {
    task_name: "Task Name",
    schedules: [
      {
        start_at: "2025-12-23",   // from most recent to oldest
        end_at: nil,
        hours_per_week: 10
      },
      {
        start_at: "2025-12-21",
        end_at: "2025-12-23",
        hours_per_week: 20
      }
    ]
  }
]
```

`session_history_1.json`
```
[
  {
    id: uuid,                          // from most recent to oldest
    task_name: "Task Name 2",
    start_at: "2025-12-22T23:55:00",
    end_at: "2025-12-23T00:05:00",     // Active Task
    notes: "yyyy"
  },
  {
    id: uuid,
    task_name: "Task Name",
    start_at: "2025-12-23T00:12:00",   // Always cut to minute
    end_at: nil, // Active Task
    notes: "xxxx"
  }
]
```