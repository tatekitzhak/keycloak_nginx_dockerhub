locals {
  # Generates a timestamp like: 2026-02-23T14:30:05Z
  raw_time = timestamp()
  
  # Formats to: 20260223143005 (no special characters)
  formatted_time = formatdate("YYYYMMDDHHmmss", local.raw_time)
}
