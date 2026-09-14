namespace IEEEVolunteerHub.Api.Models;

public class VolunteerTask
{
    public int Id { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string AssignedToMemberId { get; set; } = string.Empty;

    public string AssignedByMemberId { get; set; } = string.Empty;

    public string Status { get; set; } = "Pending";

    public DateTime? DueDate { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? CompletedAt { get; set; }
}