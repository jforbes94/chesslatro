using Godot;
using System.Threading.Tasks;

public partial class StockfishInterface : Node
{
	public override void _Ready()
	{
		GD.Print("✅ Stockfish Interface C# script is running.");
	}

	public async Task<string> GetBestMoveAsync(string fen, int depth = 10)
	{
		GD.Print($"📥 Received FEN: {fen}, depth: {depth}");
		await Task.Delay(100);  // Simulate a delay for testing purposes
		string dummyMove = "e7e5";
		GD.Print($"📤 Returning move: {dummyMove}");
		return dummyMove;
	}
}
