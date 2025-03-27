using Godot;
using System.Diagnostics;
using System.IO;

[GlobalClass]
public partial class StockfishInterface : Node
{
	[Export] public string StockfishPath { get; set; } = "res://stockfish/stockfish";

	public string GetBestMove(string fen)
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

		process.Start();

		process.StandardInput.WriteLine($"position fen {fen}");
		process.StandardInput.WriteLine("go depth 10");
		process.StandardInput.Flush();

		string bestMove = "";

		while (!process.StandardOutput.EndOfStream)
		{
			var line = process.StandardOutput.ReadLine();
			if (line.StartsWith("bestmove"))
			{
				bestMove = line.Split(' ')[1];
				break;
			}
		}

		process.StandardInput.WriteLine("quit");
		process.WaitForExit();

		return bestMove;
	}
}
