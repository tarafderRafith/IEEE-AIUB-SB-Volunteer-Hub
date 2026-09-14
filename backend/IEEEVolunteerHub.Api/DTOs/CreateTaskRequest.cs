namespace IEEEVolunteerHub.Api.DTOs;

public class CreateTaskRequest
{
    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string AssignedToMemberId { get; set; } = string.Empty;

    public DateTime? DueDate { get; set; }
}