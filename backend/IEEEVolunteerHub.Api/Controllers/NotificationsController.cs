using System.Security.Claims;
using IEEEVolunteerHub.Api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IEEEVolunteerHub.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly ApplicationDbContext _db;

    public NotificationsController(ApplicationDbContext db)
    {
        _db = db;
    }

    private string? GetCurrentMemberId()
    {
        return User.FindFirstValue("memberId")
            ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
    }

    [HttpGet("my-notifications")]
    public async Task<IActionResult> GetMyNotifications()
    {
        var memberId = GetCurrentMemberId();

        if (string.IsNullOrWhiteSpace(memberId))
        {
            return Unauthorized(new
            {
                message = "Unable to identify the logged-in member."
            });
        }

        var notifications = await _db.Notifications
            .Where(n => n.RecipientMemberId == memberId)
            .OrderByDescending(n => n.CreatedAt)
            .Select(n => new
            {
                n.Id,
                recipientMemberId = n.RecipientMemberId,
                n.Title,
                n.Message,
                n.Type,
                isRead = n.IsRead,
                createdAt = n.CreatedAt,
                readAt = n.ReadAt,
                relatedTaskId = n.RelatedTaskId,
                relatedEventId = n.RelatedEventId
            })
            .ToListAsync();

        return Ok(notifications);
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var memberId = GetCurrentMemberId();

        if (string.IsNullOrWhiteSpace(memberId))
        {
            return Unauthorized(new
            {
                message = "Unable to identify the logged-in member."
            });
        }

        var count = await _db.Notifications
            .CountAsync(n =>
                n.RecipientMemberId == memberId &&
                !n.IsRead);

        return Ok(new
        {
            count
        });
    }

    [HttpPut("{id:int}/read")]
    public async Task<IActionResult> MarkAsRead(int id)
    {
        var memberId = GetCurrentMemberId();

        if (string.IsNullOrWhiteSpace(memberId))
        {
            return Unauthorized(new
            {
                message = "Unable to identify the logged-in member."
            });
        }

        var notification = await _db.Notifications
            .FirstOrDefaultAsync(n =>
                n.Id == id &&
                n.RecipientMemberId == memberId);

        if (notification == null)
        {
            return NotFound(new
            {
                message = "Notification not found."
            });
        }

        notification.IsRead = true;
        notification.ReadAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "Notification marked as read."
        });
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var memberId = GetCurrentMemberId();

        if (string.IsNullOrWhiteSpace(memberId))
        {
            return Unauthorized(new
            {
                message = "Unable to identify the logged-in member."
            });
        }

        var notifications = await _db.Notifications
            .Where(n =>
                n.RecipientMemberId == memberId &&
                !n.IsRead)
            .ToListAsync();

        var readTime = DateTime.UtcNow;

        foreach (var notification in notifications)
        {
            notification.IsRead = true;
            notification.ReadAt = readTime;
        }

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "All notifications marked as read.",
            count = notifications.Count
        });
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> DeleteNotification(int id)
    {
        var memberId = GetCurrentMemberId();

        if (string.IsNullOrWhiteSpace(memberId))
        {
            return Unauthorized(new
            {
                message = "Unable to identify the logged-in member."
            });
        }

        var notification = await _db.Notifications
            .FirstOrDefaultAsync(n =>
                n.Id == id &&
                n.RecipientMemberId == memberId);

        if (notification == null)
        {
            return NotFound(new
            {
                message = "Notification not found."
            });
        }

        _db.Notifications.Remove(notification);

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "Notification deleted."
        });
    }

    [HttpDelete("all")]
    public async Task<IActionResult> DeleteAllNotifications()
    {
        var memberId = GetCurrentMemberId();

        if (string.IsNullOrWhiteSpace(memberId))
        {
            return Unauthorized(new
            {
                message = "Unable to identify the logged-in member."
            });
        }

        var notifications = await _db.Notifications
            .Where(n => n.RecipientMemberId == memberId)
            .ToListAsync();

        _db.Notifications.RemoveRange(notifications);

        await _db.SaveChangesAsync();

        return Ok(new
        {
            message = "All notifications deleted.",
            count = notifications.Count
        });
    }
}