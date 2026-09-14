namespace IEEEVolunteerHub.Api.DTOs;

public class RegisterRequest
{
    public string MemberId { get; set; } = string.Empty;

    public string FullName { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string Phone { get; set; } = string.Empty;

    public string Password { get; set; } = string.Empty;

    public string Role { get; set; } = "Volunteer";

    public string? Team { get; set; }
}