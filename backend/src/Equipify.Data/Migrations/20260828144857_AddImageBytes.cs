using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Equipify.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddImageBytes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<byte[]>(
                name: "MainImageBytes",
                table: "Listings",
                type: "bytea",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "MainImageContentType",
                table: "Listings",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<byte[]>(
                name: "ImageBytes",
                table: "ListingImages",
                type: "bytea",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ContentType",
                table: "ListingImages",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "MainImageBytes",
                table: "Listings");

            migrationBuilder.DropColumn(
                name: "MainImageContentType",
                table: "Listings");

            migrationBuilder.DropColumn(
                name: "ImageBytes",
                table: "ListingImages");

            migrationBuilder.DropColumn(
                name: "ContentType",
                table: "ListingImages");
        }
    }
}
