using IEEEVolunteerHub.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace IEEEVolunteerHub.Api.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();

    public DbSet<VolunteerTask> Tasks => Set<VolunteerTask>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.Id);

            entity.HasIndex(u => u.MemberId)
                .IsUnique();

            entity.HasIndex(u => u.Email)
                .IsUnique();

            entity.Property(u => u.MemberId)
                .IsRequired()
                .HasMaxLength(50);

            entity.Property(u => u.FullName)
                .IsRequired()
                .HasMaxLength(150);

            entity.Property(u => u.Email)
                .IsRequired()
                .HasMaxLength(150);

            entity.Property(u => u.Phone)
                .IsRequired()
                .HasMaxLength(30);

            entity.Property(u => u.PasswordHash)
                .IsRequired();

            entity.Property(u => u.Role)
                .IsRequired()
                .HasMaxLength(30);

            entity.Property(u => u.Team)
                .HasMaxLength(100);

            entity.Property(u => u.FcmToken);

            entity.Property(u => u.CreatedAt)
                .IsRequired();

            entity.Property(u => u.UpdatedAt)
                .IsRequired();
        });

        modelBuilder.Entity<VolunteerTask>(entity =>
        {
            entity.HasKey(t => t.Id);

            entity.Property(t => t.Title)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(t => t.Description)
                .IsRequired();

            entity.Property(t => t.AssignedToMemberId)
                .IsRequired()
                .HasMaxLength(50);

            entity.Property(t => t.AssignedByMemberId)
                .IsRequired()
                .HasMaxLength(50);

            entity.Property(t => t.Status)
                .IsRequired()
                .HasMaxLength(30);

            entity.HasIndex(t => t.AssignedToMemberId);

            entity.HasIndex(t => t.AssignedByMemberId);

            entity.HasIndex(t => t.Status);
        });
    }
}