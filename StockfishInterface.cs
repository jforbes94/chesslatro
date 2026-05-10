using Godot;
using System;
using System.Collections.Generic;
using System.Diagnostics;

[GlobalClass]
public partial class StockfishInterface : Node
{
	[Export]
	public string StockfishPath { get; set; } = "res://stockfish/fairy-stockfish.exe";

	[Export]
	public string Variant { get; set; } = "chess";

	[Export]
	public int MultiPV { get; set; } = 1;

	// Time budget per move in milliseconds
	[Export]
	public int MoveTimeMs { get; set; } = 300;

	// Last evaluation in centipawns, always from White's perspective (positive = White winning)
	public int LastScoreCentipawns { get; private set; } = 0;

	private bool debugStockfishOutput = false;
	private Random _rng = new Random();

	// Full search: returns best move and updates LastScoreCentipawns
	public string GetBestMove(string fen)
	{
		bool whiteToMove = FenActiveColor(fen) == "w";
		string chosenMove = null;

		RunEngine(fen, $"go movetime {MoveTimeMs}", (line, candidates) =>
		{
			ParseScoreLine(line, whiteToMove);

			if (line.Contains("multipv") && line.Contains(" pv "))
			{
				int pvIndex = line.IndexOf(" pv ");
				if (pvIndex >= 0)
				{
					string firstMove = line.Substring(pvIndex + 4).Trim().Split(' ')[0];
					if (!candidates.Contains(firstMove))
						candidates.Add(firstMove);
				}
			}
		}, ref chosenMove);

		if (chosenMove != null)
			GD.Print($"Best move: {chosenMove}  eval: {LastScoreCentipawns}cp (White perspective)");

		return chosenMove;
	}

	// Lightweight eval only — depth 5, no MultiPV needed
	public int GetEvaluation(string fen)
	{
		bool whiteToMove = FenActiveColor(fen) == "w";
		string unused = null;

		var process = StartProcess();
		if (process == null) return 0;

		try
		{
			Handshake(process, "chess", 1);
			process.StandardInput.WriteLine($"position fen {fen}");
			process.StandardInput.WriteLine("go depth 5");
			process.StandardInput.Flush();

			while (true)
			{
				string line = process.StandardOutput.ReadLine();
				if (line == null) break;
				if (debugStockfishOutput) GD.Print("Fairy-Stockfish: " + line);
				ParseScoreLine(line, whiteToMove);
				if (line.StartsWith("bestmove")) break;
			}

			process.StandardInput.WriteLine("quit");
			process.StandardInput.Flush();
			process.WaitForExit();
		}
		catch (Exception e) { GD.PrintErr("Eval error: " + e.Message); }

		GD.Print($"Baseline eval: {LastScoreCentipawns}cp (White perspective)");
		return LastScoreCentipawns;
	}

	// --- Helpers ---

	private void ParseScoreLine(string line, bool whiteToMove)
	{
		if (!line.StartsWith("info")) return;

		if (line.Contains(" score cp "))
		{
			int idx = line.IndexOf(" score cp ") + 10;
			int end = line.IndexOf(' ', idx);
			string cpStr = end >= 0 ? line.Substring(idx, end - idx) : line.Substring(idx);
			if (int.TryParse(cpStr, out int cp))
				LastScoreCentipawns = whiteToMove ? cp : -cp;
		}
		else if (line.Contains(" score mate "))
		{
			int idx = line.IndexOf(" score mate ") + 12;
			int end = line.IndexOf(' ', idx);
			string mateStr = end >= 0 ? line.Substring(idx, end - idx) : line.Substring(idx);
			if (int.TryParse(mateStr, out int mate))
			{
				bool whiteMating = (whiteToMove && mate > 0) || (!whiteToMove && mate < 0);
				LastScoreCentipawns = whiteMating ? 9999 : -9999;
			}
		}
	}

	private static string FenActiveColor(string fen)
	{
		var parts = fen.Split(' ');
		return parts.Length >= 2 ? parts[1] : "w";
	}

	private Process StartProcess()
	{
		var process = new Process
		{
			StartInfo = new ProcessStartInfo
			{
				FileName = ProjectSettings.GlobalizePath(StockfishPath),
				RedirectStandardInput = true,
				RedirectStandardOutput = true,
				UseShellExecute = false,
				CreateNoWindow = true
			}
		};
		try { process.Start(); return process; }
		catch (Exception e) { GD.PrintErr("Failed to start engine: " + e.Message); return null; }
	}

	private void Handshake(Process process, string variant, int multiPV)
	{
		process.StandardInput.WriteLine("uci");
		process.StandardInput.Flush();
		while (true)
		{
			string line = process.StandardOutput.ReadLine();
			if (debugStockfishOutput) GD.Print("Fairy-Stockfish: " + line);
			if (line == null || line == "uciok") break;
		}
		process.StandardInput.WriteLine($"setoption name UCI_Variant value {variant}");
		process.StandardInput.WriteLine($"setoption name MultiPV value {multiPV}");
		process.StandardInput.WriteLine("isready");
		process.StandardInput.Flush();
		while (true)
		{
			string line = process.StandardOutput.ReadLine();
			if (debugStockfishOutput) GD.Print("Fairy-Stockfish: " + line);
			if (line == null || line == "readyok") break;
		}
	}

	private void RunEngine(string fen, string goCommand, Action<string, List<string>> onLine, ref string chosenMove)
	{
		var process = StartProcess();
		if (process == null) return;

		var candidates = new List<string>();

		try
		{
			Handshake(process, Variant, MultiPV);
			process.StandardInput.WriteLine($"position fen {fen}");
			process.StandardInput.WriteLine(goCommand);
			process.StandardInput.Flush();

			while (true)
			{
				string line = process.StandardOutput.ReadLine();
				if (line == null) break;
				if (debugStockfishOutput) GD.Print("Fairy-Stockfish: " + line);

				onLine(line, candidates);

				if (line.StartsWith("bestmove"))
				{
					if (candidates.Count == 0)
					{
						var parts = line.Split(' ');
						if (parts.Length >= 2) candidates.Add(parts[1]);
					}
					break;
				}
			}

			if (candidates.Count > 0)
				chosenMove = candidates[_rng.Next(candidates.Count)];

			process.StandardInput.WriteLine("quit");
			process.StandardInput.Flush();
			process.WaitForExit();
		}
		catch (Exception e) { GD.PrintErr("Fairy-Stockfish error: " + e.Message); }
	}
}
