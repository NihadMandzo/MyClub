// using System;
// using System.Collections.Generic;
// using System.ComponentModel.DataAnnotations;

// namespace MyClub.Model.Requests
// {
//     public class CartUpsertRequest
//     {
//         [Required(ErrorMessage = "User is required")]
//         public int UserId { get; set; }
        
//         public List<CartItemUpsertRequest> Items { get; set; } = new List<CartItemUpsertRequest>();
//     }
// } 