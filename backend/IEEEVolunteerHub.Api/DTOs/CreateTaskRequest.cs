namespace IEEEVolunteerHub.Api.DTOs;

public class CreateTaskRequest
{
    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string AssignedToMemberId { get; set; } = string.Empty;

    public string? Team { get; set; }

    public string Priority { get; set; } = "Medium";

    public int Points { get; set; } = 0;

    public DateTime? DueDate { get; set; }
}