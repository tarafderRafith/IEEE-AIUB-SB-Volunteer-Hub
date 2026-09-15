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
    // CREATE / ASSIGN TASK
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

        // Validate priority
        string priority =
            string.IsNullOrWhiteSpace(request.Priority)
                ? "Medium"
                : request.Priority.Trim();

        var allowedPriorities = new[]
        {
            "Low",
            "Medium",
            "High"
        };

        if (!allowedPriorities.Contains(
                priority,
                StringComparer.OrdinalIgnoreCase))
        {
            return BadRequest(new
            {
                message = "Priority must be Low, Medium, or High."
            });
        }

        // Normalize priority
        priority = allowedPriorities
            .First(p => p.Equals(
                priority,
                StringComparison.OrdinalIgnoreCase));

        // Validate points
        if (request.Points < 0 || request.Points > 1000)
        {
            return BadRequest(new
            {
                message = "Points must be between 0 and 1000."
            });
        }

        var task = new VolunteerTask
        {
            Title = request.Title.Trim(),

            Description = request.Description.Trim(),

            AssignedToMemberId = volunteer.MemberId,

            AssignedByMemberId = executiveMemberId,

            Team = string.IsNullOrWhiteSpace(request.Team)
                ? volunteer.Team
                : request.Team.Trim(),

            Priority = priority,

            Points = request.Points,

            Status = "Pending",

            DueDate = request.DueDate,

            CreatedAt = DateTime.UtcNow,

            UpdatedAt = DateTime.UtcNow,

            StartedAt = null,

            CompletedAt = null
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
                task.Team,
                task.Priority,
                task.Points,
                task.Status,
                task.DueDate,
                task.CreatedAt,
                task.UpdatedAt,
                task.StartedAt,
                task.CompletedAt
            }
        });
    }

    // =========================================================
    // GET MY TASKS
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
            .Where(t =>
                t.AssignedToMemberId == memberId)
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new
            {
                t.Id,
                t.Title,
                t.Description,
                t.AssignedToMemberId,
                t.AssignedByMemberId,
                t.Team,
                t.Priority,
                t.Points,
                t.Status,
                t.DueDate,
                t.CreatedAt,
                t.UpdatedAt,
                t.StartedAt,
                t.CompletedAt
            })
            .ToListAsync();

        return Ok(tasks);
    }

    // =========================================================
    // GET SINGLE TASK
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
            .FirstOrDefaultAsync(t =>
                t.Id == id);

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
            task.Team,
            task.Priority,
            task.Points,
            task.Status,
            task.DueDate,
            task.CreatedAt,
            task.UpdatedAt,
            task.StartedAt,
            task.CompletedAt
        });
    }

    // =========================================================
    // UPDATE TASK STATUS
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

        // When volunteer starts the task
        if (status == "In Process")
        {
            if (task.StartedAt == null)
            {
                task.StartedAt = DateTime.UtcNow;
            }

            task.CompletedAt = null;
        }

        // When volunteer marks the task done
        else if (status == "Done")
        {
            if (task.StartedAt == null)
            {
                task.StartedAt = DateTime.UtcNow;
            }

            task.CompletedAt = DateTime.UtcNow;
        }

        // When task is returned to pending
        else if (status == "Pending")
        {
            task.StartedAt = null;

            task.CompletedAt = null;
        }

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message =
                "Task status updated successfully.",

            task = new
            {
                task.Id,
                task.Title,
                task.Description,
                task.AssignedToMemberId,
                task.AssignedByMemberId,
                task.Team,
                task.Priority,
                task.Points,
                task.Status,
                task.DueDate,
                task.CreatedAt,
                task.UpdatedAt,
                task.StartedAt,
                task.CompletedAt
            }
        });
    }

    // =========================================================
    // TASKS ASSIGNED BY CURRENT EXECUTIVE
    // =========================================================

    [HttpGet("assigned-by-me")]
    [Authorize(Roles = "Executive")]
    public async Task<IActionResult> GetTasksAssignedByMe()
    {
        string memberId =
            User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? string.Empty;

        var tasks = await _db.Tasks
            .Where(t =>
                t.AssignedByMemberId == memberId)
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new
            {
                t.Id,
                t.Title,
                t.Description,
                t.AssignedToMemberId,
                t.AssignedByMemberId,
                t.Team,
                t.Priority,
                t.Points,
                t.Status,
                t.DueDate,
                t.CreatedAt,
                t.UpdatedAt,
                t.StartedAt,
                t.CompletedAt
            })
            .ToListAsync();

        return Ok(tasks);
    }

    // =========================================================
    // GET ALL TASKS
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
                t.Team,
                t.Priority,
                t.Points,
                t.Status,
                t.DueDate,
                t.CreatedAt,
                t.UpdatedAt,
                t.StartedAt,
                t.CompletedAt
            })
            .ToListAsync();

        return Ok(tasks);
    }
}