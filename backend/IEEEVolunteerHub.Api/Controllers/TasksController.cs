using System.Security.Claims;
using IEEEVolunteerHub.Api.Data;
using IEEEVolunteerHub.Api.DTOs;
using IEEEVolunteerHub.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IEEEVolunteerHub.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TasksController : ControllerBase
{
    private readonly ApplicationDbContext _db;

    public TasksController(ApplicationDbContext db)
    {
        _db = db;
    }

    // =========================================================
    // EXECUTIVE: CREATE AND ASSIGN TASK
    // =========================================================

    [HttpPost]
    [Authorize(Roles = "Executive")]
    public async Task<IActionResult> CreateTask(
        [FromBody] CreateTaskRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Title))
        {
            return BadRequest(new
            {
                message = "Task title is required."
            });
        }

        if (string.IsNullOrWhiteSpace(request.Description))
        {
            return BadRequest(new
            {
                message = "Task description is required."
            });
        }

        if (string.IsNullOrWhiteSpace(request.AssignedToMemberId))
        {
            return BadRequest(new
            {
                message = "Volunteer member ID is required."
            });
        }

        string executiveMemberId =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? string.Empty;

        if (string.IsNullOrWhiteSpace(executiveMemberId))
        {
            return Unauthorized(new
            {
                message = "Invalid authentication token."
            });
        }

        string volunteerMemberId =
            request.AssignedToMemberId.Trim();

        var volunteer = await _db.Users
            .FirstOrDefaultAsync(u =>
                u.MemberId == volunteerMemberId);

        if (volunteer == null)
        {
            return NotFound(new
            {
                message = "Volunteer not found."
            });
        }

        if (!volunteer.IsActive)
        {
            return BadRequest(new
            {
                message = "This volunteer account is inactive."
            });
        }

        if (!volunteer.Role.Equals(
                "Volunteer",
                StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new
            {
                message = "Tasks can only be assigned to volunteers."
            });
        }

        var task = new IEEEVolunteerHub.Api.Models.VolunteerTask
        {
            Title = request.Title.Trim(),

            Description = request.Description.Trim(),

            AssignedToMemberId = volunteer.MemberId,

            AssignedByMemberId = executiveMemberId,

            Status = "Pending",

            DueDate = request.DueDate,

            CreatedAt = DateTime.UtcNow,

            UpdatedAt = DateTime.UtcNow
        };

        _db.Tasks.Add(task);

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "Task assigned successfully.",

            task = new
            {
                task.Id,
                task.Title,
                task.Description,
                task.AssignedToMemberId,
                task.AssignedByMemberId,
                task.Status,
                task.DueDate,
                task.CreatedAt,
                task.UpdatedAt,
                task.CompletedAt
            }
        });
    }


    // =========================================================
    // VOLUNTEER: GET MY TASKS
    // =========================================================

    [HttpGet("my-tasks")]
    [Authorize(Roles = "Volunteer")]
    public async Task<IActionResult> GetMyTasks()
    {
        string memberId =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? string.Empty;

        if (string.IsNullOrWhiteSpace(memberId))
        {
            return Unauthorized(new
            {
                message = "Invalid authentication token."
            });
        }

        var tasks = await _db.Tasks
            .Where(t => t.AssignedToMemberId == memberId)
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new
            {
                t.Id,
                t.Title,
                t.Description,
                t.AssignedToMemberId,
                t.AssignedByMemberId,
                t.Status,
                t.DueDate,
                t.CreatedAt,
                t.UpdatedAt,
                t.CompletedAt
            })
            .ToListAsync();

        return Ok(tasks);
    }


    // =========================================================
    // VOLUNTEER: GET SINGLE TASK
    // =========================================================

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetTask(int id)
    {
        string memberId =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? string.Empty;

        string role =
            User.FindFirstValue(ClaimTypes.Role)
            ?? string.Empty;

        var task = await _db.Tasks
            .FirstOrDefaultAsync(t => t.Id == id);

        if (task == null)
        {
            return NotFound(new
            {
                message = "Task not found."
            });
        }

        bool canView =
            role.Equals(
                "Executive",
                StringComparison.OrdinalIgnoreCase)
            ||
            task.AssignedToMemberId == memberId
            ||
            task.AssignedByMemberId == memberId;

        if (!canView)
        {
            return Forbid();
        }

        return Ok(new
        {
            task.Id,
            task.Title,
            task.Description,
            task.AssignedToMemberId,
            task.AssignedByMemberId,
            task.Status,
            task.DueDate,
            task.CreatedAt,
            task.UpdatedAt,
            task.CompletedAt
        });
    }


    // =========================================================
    // VOLUNTEER: UPDATE TASK STATUS
    // =========================================================

    [HttpPut("{id:int}/status")]
    [Authorize(Roles = "Volunteer")]
    public async Task<IActionResult> UpdateTaskStatus(
        int id,
        [FromBody] UpdateTaskStatusRequest request)
    {
        string memberId =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? string.Empty;

        string status =
            request.Status.Trim();

        var allowedStatuses = new[]
        {
            "Pending",
            "In Process",
            "Done"
        };

        if (!allowedStatuses.Contains(status))
        {
            return BadRequest(new
            {
                message =
                    "Status must be Pending, In Process, or Done."
            });
        }

        var task = await _db.Tasks
            .FirstOrDefaultAsync(t =>
                t.Id == id &&
                t.AssignedToMemberId == memberId);

        if (task == null)
        {
            return NotFound(new
            {
                message = "Task not found."
            });
        }

        task.Status = status;

        task.UpdatedAt = DateTime.UtcNow;

        if (status == "Done")
        {
            task.CompletedAt = DateTime.UtcNow;
        }
        else
        {
            task.CompletedAt = null;
        }

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "Task status updated successfully.",

            task = new
            {
                task.Id,
                task.Title,
                task.Description,
                task.AssignedToMemberId,
                task.AssignedByMemberId,
                task.Status,
                task.DueDate,
                task.CreatedAt,
                task.UpdatedAt,
                task.CompletedAt
            }
        });
    }


    // =========================================================
    // EXECUTIVE: GET TASKS ASSIGNED BY ME
    // =========================================================

    [HttpGet("assigned-by-me")]
    [Authorize(Roles = "Executive")]
    public async Task<IActionResult> GetTasksAssignedByMe()
    {
        string memberId =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? string.Empty;

        var tasks = await _db.Tasks
            .Where(t => t.AssignedByMemberId == memberId)
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new
            {
                t.Id,
                t.Title,
                t.Description,
                t.AssignedToMemberId,
                t.AssignedByMemberId,
                t.Status,
                t.DueDate,
                t.CreatedAt,
                t.UpdatedAt,
                t.CompletedAt
            })
            .ToListAsync();

        return Ok(tasks);
    }


    // =========================================================
    // EXECUTIVE: GET ALL TASKS
    // =========================================================

    [HttpGet("all")]
    [Authorize(Roles = "Executive")]
    public async Task<IActionResult> GetAllTasks()
    {
        var tasks = await _db.Tasks
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new
            {
                t.Id,
                t.Title,
                t.Description,
                t.AssignedToMemberId,
                t.AssignedByMemberId,
                t.Status,
                t.DueDate,
                t.CreatedAt,
                t.UpdatedAt,
                t.CompletedAt
            })
            .ToListAsync();

        return Ok(tasks);
    }
}