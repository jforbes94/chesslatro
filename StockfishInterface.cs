using Godot;
using System.Diagnostics;
using System.IO;

[GlobalClass]
public partial class StockfishInterface : Node
{
	[Export]
	public string StockfishPath { get; set; } = "res://stockfish/stockfish";

	// Toggle this to true if you want to see all Stockfish output
	private bool debugStockfishOutput = false;

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

		string bestMove = null;

		try
		{
			process.Start();

			process.StandardInput.WriteLine($"position fen {fen}");
			process.StandardInput.WriteLine("go depth 10");
			process.StandardInput.Flush();

			while (true)
			{
				string line = process.StandardOutput.ReadLine();
				if (line == null)
					break;

				if (debugStockfishOutput)
					GD.Print("Stockfish: " + line);

				if (line.StartsWith("bestmove"))
				{
					var parts = line.Split(' ');
					if (parts.Length >= 2)
					{
						bestMove = parts[1];
						GD.Print("Best move: " + bestMove);
					}
					else
					{
						GD.Print("Warning: Malformed bestmove line");
					}
					break;
				}
			}

			process.StandardInput.WriteLine("quit");
			process.StandardInput.Flush();
			process.WaitForExit();
		}
		catch (System.Exception e)
		{
			GD.PrintErr("Stockfish error: " + e.Message);
		}

		return bestMove;
	}
}
