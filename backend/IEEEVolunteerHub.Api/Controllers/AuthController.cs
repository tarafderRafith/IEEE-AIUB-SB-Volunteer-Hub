using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using IEEEVolunteerHub.Api.Data;
using IEEEVolunteerHub.Api.DTOs;
using IEEEVolunteerHub.Api.Models;
using IEEEVolunteerHub.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace IEEEVolunteerHub.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    private readonly PasswordService _passwordService;
    private readonly IConfiguration _configuration;

    public AuthController(
        ApplicationDbContext db,
        PasswordService passwordService,
        IConfiguration configuration)
    {
        _db = db;
        _passwordService = passwordService;
        _configuration = configuration;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.MemberId) ||
            string.IsNullOrWhiteSpace(request.FullName) ||
            string.IsNullOrWhiteSpace(request.Email) ||
            string.IsNullOrWhiteSpace(request.Phone) ||
            string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new
            {
                message = "All required fields must be provided."
            });
        }

        if (request.Password.Length < 6)
        {
            return BadRequest(new
            {
                message = "Password must be at least 6 characters."
            });
        }

        string role = request.Role.Trim();

        if (!role.Equals("Volunteer", StringComparison.OrdinalIgnoreCase) &&
            !role.Equals("Executive", StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new
            {
                message = "Role must be Volunteer or Executive."
            });
        }

        bool memberExists = await _db.Users
            .AnyAsync(u => u.MemberId == request.MemberId.Trim());

        if (memberExists)
        {
            return Conflict(new
            {
                message = "This member ID is already registered."
            });
        }

        bool emailExists = await _db.Users
            .AnyAsync(u => u.Email == request.Email.Trim().ToLower());

        if (emailExists)
        {
            return Conflict(new
            {
                message = "This email is already registered."
            });
        }

        var user = new User
        {
            MemberId = request.MemberId.Trim(),
            FullName = request.FullName.Trim(),
            Email = request.Email.Trim().ToLower(),
            Phone = request.Phone.Trim(),
            PasswordHash = _passwordService.HashPassword(request.Password),
            Role = role.Equals("Executive", StringComparison.OrdinalIgnoreCase)
                ? "Executive"
                : "Volunteer",
            Team = string.IsNullOrWhiteSpace(request.Team)
                ? null
                : request.Team.Trim(),
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.Users.Add(user);

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "Registration successful.",
            user = new
            {
                user.Id,
                user.MemberId,
                user.FullName,
                user.Email,
                user.Phone,
                user.Role,
                user.Team
            }
        });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.MemberId) ||
            string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new
            {
                message = "Member ID and password are required."
            });
        }

        var user = await _db.Users
            .FirstOrDefaultAsync(u =>
                u.MemberId == request.MemberId.Trim());

        if (user == null)
        {
            return Unauthorized(new
            {
                message = "Invalid member ID or password."
            });
        }

        if (!user.IsActive)
        {
            return Unauthorized(new
            {
                message = "This account has been deactivated."
            });
        }

        bool passwordValid = _passwordService.VerifyPassword(
            request.Password,
            user.PasswordHash
        );

        if (!passwordValid)
        {
            return Unauthorized(new
            {
                message = "Invalid member ID or password."
            });
        }

        string token = GenerateJwtToken(user);

        return Ok(new
        {
            message = "Login successful.",
            token,
            user = new
            {
                user.Id,
                user.MemberId,
                user.FullName,
                user.Email,
                user.Phone,
                user.Role,
                user.Team
            }
        });
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        string? memberId = User.FindFirstValue(
            ClaimTypes.NameIdentifier
        );

        if (string.IsNullOrWhiteSpace(memberId))
        {
            return Unauthorized(new
            {
                message = "Invalid authentication token."
            });
        }

        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.MemberId == memberId);

        if (user == null)
        {
            return NotFound(new
            {
                message = "User not found."
            });
        }

        return Ok(new
        {
            user.Id,
            user.MemberId,
            user.FullName,
            user.Email,
            user.Phone,
            user.Role,
            user.Team
        });
    }

    [Authorize]
    [HttpPost("fcm-token")]
    public async Task<IActionResult> UpdateFcmToken(
        [FromBody] FcmTokenRequest request)
    {
        string? memberId = User.FindFirstValue(
            ClaimTypes.NameIdentifier
        );

        if (string.IsNullOrWhiteSpace(memberId))
        {
            return Unauthorized();
        }

        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.MemberId == memberId);

        if (user == null)
        {
            return NotFound(new
            {
                message = "User not found."
            });
        }

        user.FcmToken = request.Token;
        user.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "FCM token updated successfully."
        });
    }

    private string GenerateJwtToken(User user)
    {
        var jwtSection = _configuration.GetSection("Jwt");

        string key = jwtSection["Key"]
            ?? throw new InvalidOperationException("JWT key is missing.");

        string issuer = jwtSection["Issuer"]
            ?? throw new InvalidOperationException("JWT issuer is missing.");

        string audience = jwtSection["Audience"]
            ?? throw new InvalidOperationException("JWT audience is missing.");

        int expirationMinutes =
            int.TryParse(jwtSection["ExpirationMinutes"], out int minutes)
                ? minutes
                : 10080;

        var claims = new List<Claim>
        {
            new(
                ClaimTypes.NameIdentifier,
                user.MemberId
            ),
            new(
                ClaimTypes.Name,
                user.FullName
            ),
            new(
                ClaimTypes.Role,
                user.Role
            ),
            new(
                "memberId",
                user.MemberId
            ),
            new(
                "userId",
                user.Id.ToString()
            )
        };

        var securityKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(key)
        );

        var credentials = new SigningCredentials(
            securityKey,
            SecurityAlgorithms.HmacSha256
        );

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expirationMinutes),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

public class FcmTokenRequest
{
    public string Token { get; set; } = string.Empty;
}