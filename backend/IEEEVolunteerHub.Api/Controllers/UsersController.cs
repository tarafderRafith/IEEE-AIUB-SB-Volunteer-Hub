using IEEEVolunteerHub.Api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IEEEVolunteerHub.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly ApplicationDbContext _db;

    public UsersController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpGet("volunteers")]
    [Authorize(Roles = "Executive")]
    public async Task<IActionResult> GetVolunteers()
    {
        var volunteers = await _db.Users
            .Where(u =>
                u.Role == "Volunteer" &&
                u.IsActive)
            .OrderBy(u => u.FullName)
            .Select(u => new
            {
                u.Id,
                u.MemberId,
                u.FullName,
                u.Email,
                u.Phone,
                u.Team,
                u.Role,
                u.IsActive
            })
            .ToListAsync();

        return Ok(volunteers);
    }

    [HttpGet("executives")]
    [Authorize(Roles = "Executive")]
    public async Task<IActionResult> GetExecutives()
    {
        var executives = await _db.Users
            .Where(u =>
                u.Role == "Executive" &&
                u.IsActive)
            .OrderBy(u => u.FullName)
            .Select(u => new
            {
                u.Id,
                u.MemberId,
                u.FullName,
                u.Email,
                u.Phone,
                u.Team,
                u.Role,
                u.IsActive
            })
            .ToListAsync();

        return Ok(executives);
    }

    [HttpGet("{memberId}")]
    [Authorize]
    public async Task<IActionResult> GetUser(string memberId)
    {
        if (string.IsNullOrWhiteSpace(memberId))
        {
            return BadRequest(new
            {
                message = "Member ID is required."
            });
        }

        var user = await _db.Users
            .Where(u => u.MemberId == memberId)
            .Select(u => new
            {
                u.Id,
                u.MemberId,
                u.FullName,
                u.Email,
                u.Phone,
                u.Team,
                u.Role,
                u.IsActive,
                u.CreatedAt,
                u.UpdatedAt
            })
            .FirstOrDefaultAsync();

        if (user == null)
        {
            return NotFound(new
            {
                message = "User not found."
            });
        }

        return Ok(user);
    }
}