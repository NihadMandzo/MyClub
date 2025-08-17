using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MyClub.Model.Requests;
using MyClub.Model.Responses;
using MyClub.Model.SearchObjects;

namespace MyClub.Services
{
    public interface IUserService : ICRUDService<UserResponse, UserSearchObject, UserUpsertRequest, UserUpsertRequest>
    {
        Task<bool> ChangePasswordAsync(ChangePasswordRequest request);
        Task<AuthResponse> AuthenticateAsync(LoginRequest request);
        Task<UserResponse> GetMeAsync();
        Task<bool> HasActiveUserMembership();
        Task<bool> DeactivateSelfAsync();

    }
} 