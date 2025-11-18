# How to Pause Console.app and Save Logs

## Method 1: Pause Button (Easiest)

At the **top of Console.app**, look for a **Pause button** (looks like two vertical bars ||).

1. Before chatting with Hera: Click **Pause** button
2. Clear the console: **Edit → Clear Display** (or ⌘+K)
3. Click **Resume** button (looks like ▶)
4. Chat with Hera
5. As soon as Hera responds, click **Pause** button again
6. Now you can scroll through the frozen logs

---

## Method 2: Save Logs to File (Better!)

Instead of trying to capture scrolling logs, just save them to a file:

1. In Console.app, with "Runner" filter applied
2. Chat with Hera
3. After Hera responds, go to: **File → Save Selection As...**
4. Save to: `/tmp/console_logs.txt`
5. Share that file with me

---

## Method 3: Use Terminal Instead (Simplest!)

Forget Console.app entirely. Let's just tail the Flutter debug log I already created:

```bash
tail -f /tmp/flutter_apple_tts_debug.log | grep -E "AppleTTS|Error|error"
```

This will show ONLY AppleTTS-related logs in real-time in Terminal.

When you chat with Hera, you'll see the logs appear in Terminal, and they won't scroll away because there are no other logs.

Press Ctrl+C to stop.

---

## What I Actually Need

Since you chatted with Hera already, the logs are in the file I created. Let me just read that file directly.

I don't need Console.app anymore - I already have the logs saved to `/tmp/flutter_apple_tts_debug.log`!
