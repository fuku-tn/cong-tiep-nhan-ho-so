import { Check, X } from "lucide-react";
import { AdminPageHeader } from "@/components/admin/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { RequestStatusBadge } from "@/components/status-badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { servicePackages, type RequestStatus } from "@/lib/mock-data";
import { createAdminClient } from "@/lib/supabase/admin";

function formatVnd(value: number) {
  return value.toLocaleString("vi-VN") + "₫";
}

function packageLabel(id: string) {
  return servicePackages.find((p) => p.id === id)?.name ?? id;
}

const degreeLabels: Record<string, string> = {
  thpt: "THPT",
  dai_hoc: "Đại học",
  thac_si: "Thạc sĩ",
};

function formatDate(iso: string) {
  return new Date(iso).toLocaleString("vi-VN", {
    timeZone: "Asia/Ho_Chi_Minh",
    dateStyle: "short",
    timeStyle: "short",
  });
}

export default async function AdminRequestsPage() {
  const supabase = createAdminClient();
  const { data: admissionRequests, error } = await supabase
    .from("admission_requests")
    .select("id, customer_name, customer_email, country, degree_level, package, quote, status, created_at")
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);

  return (
    <>
      <AdminPageHeader
        title="Yêu cầu"
        description="Danh sách yêu cầu báo giá gửi từ trang chủ, chờ đội ngũ duyệt."
      />

      <Card>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Tên khách</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Quốc gia</TableHead>
              <TableHead>Bậc học</TableHead>
              <TableHead>Gói dịch vụ</TableHead>
              <TableHead>Báo giá</TableHead>
              <TableHead>Trạng thái</TableHead>
              <TableHead>Thời gian</TableHead>
              <TableHead className="text-right">Thao tác</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {admissionRequests.map((req) => (
              <TableRow key={req.id}>
                <TableCell className="font-medium">{req.customer_name}</TableCell>
                <TableCell>{req.customer_email}</TableCell>
                <TableCell>{req.country}</TableCell>
                <TableCell>{degreeLabels[req.degree_level] ?? req.degree_level}</TableCell>
                <TableCell>{packageLabel(req.package)}</TableCell>
                <TableCell>{formatVnd(Number(req.quote))}</TableCell>
                <TableCell>
                  <RequestStatusBadge status={req.status as RequestStatus} />
                </TableCell>
                <TableCell className="text-muted-foreground">{formatDate(req.created_at)}</TableCell>
                <TableCell>
                  <div className="flex justify-end gap-2">
                    <Button size="icon-sm" variant="outline" aria-label="Duyệt">
                      <Check className="size-3.5" />
                    </Button>
                    <Button size="icon-sm" variant="outline" aria-label="Từ chối">
                      <X className="size-3.5" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Card>
    </>
  );
}
