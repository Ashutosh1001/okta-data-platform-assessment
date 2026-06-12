import json
import os
import sys
from typing import Dict, List, Any


def load_and_filter_logs(filepath: str, target_date: str) -> List[Dict[str, Any]]:
    if not os.path.exists(filepath):
        print(f"Error: Log file '{filepath}' not found.", file=sys.stderr)
        return []

    try:
        with open(filepath, "r", encoding="utf-8") as file:
            data = json.load(file)
            
        return [
            record for record in data 
            if record.get("execution_date", "").startswith(target_date)
        ]
    except json.JSONDecodeError:
        print(f"Error: Failed to decode JSON from '{filepath}'.", file=sys.stderr)
        return []


def generate_health_report(records: List[Dict[str, Any]], target_date: str) -> None:
    print(f"=== Airflow Health Report for {target_date} ===")
    
    total_tasks = len(records)
    print(f"Total tasks: {total_tasks}")
    
    if total_tasks == 0:
        print("\nNo tasks ran on this date or log file is empty.")
        print("\nTasks by state:\n  success: 0\n  failed: 0\n  upstream_failed: 0")
        print("\nFailed tasks:\n  None")
        print("\nLongest running task:\n  N/A")
        return

    state_counts = {"success": 0, "failed": 0, "upstream_failed": 0}
    failed_task_strings = []
    
    longest_task = None
    max_duration = -1

    for record in records:
        state = record.get("state")
        dag_id = record.get("dag_id")
        task_id = record.get("task_id")
        duration = record.get("duration_seconds", 0)
        
        if state in state_counts:
            state_counts[state] += 1
            
        if state == "failed":
            failed_task_strings.append(f"{dag_id} → {task_id}")
        elif state == "upstream_failed":
            failed_task_strings.append(f"{dag_id} → {task_id} (upstream_failed)")

        if duration > max_duration:
            max_duration = duration
            longest_task = {
                "dag_id": dag_id,
                "task_id": task_id,
                "duration": duration
            }

    print("Tasks by state:")
    print(f"success: {state_counts['success']}")
    print(f"failed: {state_counts['failed']}")
    print(f"upstream failed: {state_counts['upstream_failed']}")

    print("Failed tasks:")
    if failed_task_strings:
        for task_str in failed_task_strings:
            print(task_str)
    else:
        print("None")

    print("Longest running task:")
    if longest_task:
        print(f"{longest_task['dag_id']} / {longest_task['task_id']} {longest_task['duration']} seconds")
    else:
        print("N/A")


def main():
    TARGET_FILE = "airflow_logs.json"
    TARGET_DATE = "2026-04-06"
    
    records = load_and_filter_logs(TARGET_FILE, TARGET_DATE)
    generate_health_report(records, TARGET_DATE)


if __name__ == "__main__":
    main()