namespace IEEEVolunteerHub.Api.DTOs;

public class LoginRequest
{
    public string MemberId { get; set; } = string.Empty;

    public string Password { get; set; } = string.Empty;
}