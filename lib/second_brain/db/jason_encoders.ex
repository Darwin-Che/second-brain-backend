require Protocol

Protocol.derive(Jason.Encoder, SecondBrain.Db.BrainDiskS3,
  only: [
    :id,
    :account_id,
    :file_name,
    :file_entry_cnt,
    :seq_1
  ]
)
