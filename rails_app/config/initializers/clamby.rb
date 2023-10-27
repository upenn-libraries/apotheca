# frozen_string_literal: true

Clamby.configure(
  {
    check: false,
    daemonize: true,
    config_file: Rails.root.join('clamd.conf'),
    error_clamscan_missing: true,
    error_clamscan_client_error: true,
    error_file_missing: true,
    error_file_virus: false,
    fdpass: true,
    stream: true,
    output_level: 'medium', # one of 'off', 'low', 'medium', 'high'
    executable_path_clamscan: 'clamscan',
    executable_path_clamdscan: 'clamdscan',
    executable_path_freshclam: 'freshclam'
  }
)
