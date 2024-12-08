// src/auth/middleware.rs
use std::future::{ready, Ready};
use std::pin::Pin;
use std::rc::Rc;
use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error, HttpMessage, FromRequest,
};
use actix_web::error::ErrorUnauthorized;
use futures::Future;
use crate::auth::jwt::{verify_token, Claims};

impl FromRequest for Claims {
    type Error = Error;
    type Future = Ready<Result<Self, Self::Error>>;

    fn from_request(req: &actix_web::HttpRequest, _: &mut actix_web::dev::Payload) -> Self::Future {
        ready(
            req.extensions()
                .get::<Claims>()
                .cloned()
                .ok_or_else(|| ErrorUnauthorized("인증이 필요합니다"))
        )
    }
}
pub struct AuthMiddleware;

impl<S, B> Transform<S, ServiceRequest> for AuthMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Transform = AuthMiddlewareService<S>;
    type InitError = ();
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(AuthMiddlewareService {
            service: Rc::new(service),
        }))
    }
}
pub struct AuthMiddlewareService<S> {
    service: Rc<S>,
}

impl<S, B> Service<ServiceRequest> for AuthMiddlewareService<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = Pin<Box<dyn Future<Output = Result<Self::Response, Self::Error>>>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let service = self.service.clone();

        // 인증이 필요없는 경로들 (정확한 경로 매칭)
        let public_paths = [
            "/api/v1/auth/login",
            "/api/v1/auth/register",
            "/api/v1/auth/social-login",
            "/api/v1/auth/refresh",      
            "/api/v1/health",
            "/api/v1/ws",
            "/api/v1/servers/test-connection"
        ];

        let path = req.path().trim_end_matches('/');
        if public_paths.contains(&path) {
            let fut = service.call(req);
            return Box::pin(async move {
                let res = fut.await?;
                Ok(res)
            });
        }

        // Authorization 헤더 추출
        let token = match req.headers().get("Authorization") {
            Some(header) => {
                match header.to_str() {
                    Ok(val) if val.starts_with("Bearer ") => &val[7..],
                    _ => return Box::pin(async move {
                        Err(ErrorUnauthorized("Invalid token"))
                    })
                }
            },
            None => return Box::pin(async move {
                Err(ErrorUnauthorized("Unauthorized"))
            })
        };

        // 토큰 검증
        match verify_token(token) {
            Ok(claims) => {
                // 토큰 타입 체크 추가
                if claims.token_type != "access" {
                    return Box::pin(async move {
                        Err(ErrorUnauthorized("Invalid token type"))
                    });
                }

                // 유효한 토큰이면 claims를 요청 확장에 추가
                req.extensions_mut().insert(claims);
                let fut = service.call(req);
                Box::pin(async move {
                    let res = fut.await?;
                    Ok(res)
                })
            }
            Err(_) => Box::pin(async move {
                Err(ErrorUnauthorized("Invalid token"))
            })
        }
    }
}